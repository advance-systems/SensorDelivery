using System;
using System.Diagnostics;
using System.IO;
using System.ServiceProcess;
using System.Text;
using System.Threading;

namespace SensorDelivery.WindowsService
{
    internal sealed class SensorDeliveryApiService : ServiceBase
    {
        internal const string InternalName = "SensorDeliveryApi";

        private readonly object sync = new object();
        private Process nodeProcess;
        private volatile bool stopping;
        private int restartScheduled;

        internal SensorDeliveryApiService()
        {
            ServiceName = InternalName;
            CanStop = true;
            CanShutdown = true;
            AutoLog = false;
        }

        private string RootDirectory
        {
            get { return AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar); }
        }

        private string ServerDirectory
        {
            get { return Path.Combine(RootDirectory, "Servidor"); }
        }

        private string LogDirectory
        {
            get { return Path.Combine(ServerDirectory, "logs"); }
        }

        private string ServiceLogPath
        {
            get { return Path.Combine(LogDirectory, "servico-windows.log"); }
        }

        private string ApiLogPath
        {
            get { return Path.Combine(LogDirectory, "servidor.log"); }
        }

        protected override void OnStart(string[] args)
        {
            stopping = false;
            Directory.CreateDirectory(LogDirectory);
            LogService("Serviço iniciado pelo Windows.");
            try
            {
                StartNode();
            }
            catch (Exception error)
            {
                LogService("Não foi possível iniciar a API: " + error);
                throw;
            }
        }

        protected override void OnStop()
        {
            StopNode("Serviço parado pelo Windows.");
        }

        protected override void OnShutdown()
        {
            StopNode("Windows está sendo desligado.");
        }

        private void StartNode()
        {
            lock (sync)
            {
                if (stopping)
                    return;

                if (nodeProcess != null && !nodeProcess.HasExited)
                    return;

                string nodePath = Path.Combine(RootDirectory, "Runtime", "node.exe");
                string serverPath = Path.Combine(ServerDirectory, "dist", "src", "server.js");
                string envPath = Path.Combine(ServerDirectory, ".env");

                if (!File.Exists(nodePath))
                    throw new FileNotFoundException("Runtime do Node não encontrado.", nodePath);
                if (!File.Exists(serverPath))
                    throw new FileNotFoundException("API compilada não encontrada.", serverPath);
                if (!File.Exists(envPath))
                    throw new FileNotFoundException("Configuração .env não encontrada.", envPath);

                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = nodePath;
                startInfo.Arguments = "\"" + serverPath + "\"";
                startInfo.WorkingDirectory = ServerDirectory;
                startInfo.UseShellExecute = false;
                startInfo.CreateNoWindow = true;
                startInfo.RedirectStandardOutput = true;
                startInfo.RedirectStandardError = true;

                Process process = new Process();
                process.StartInfo = startInfo;
                process.EnableRaisingEvents = true;
                process.OutputDataReceived += OnNodeOutput;
                process.ErrorDataReceived += OnNodeError;
                process.Exited += OnNodeExited;

                if (!process.Start())
                    throw new InvalidOperationException("O processo da API não pôde ser iniciado.");

                nodeProcess = process;
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                LogService("API iniciada. PID " + process.Id + ".");
            }
        }

        private void StopNode(string reason)
        {
            stopping = true;
            LogService(reason);

            Process process = null;
            lock (sync)
            {
                process = nodeProcess;
                nodeProcess = null;
            }

            if (process == null)
                return;

            try
            {
                if (!process.HasExited)
                {
                    process.Kill();
                    process.WaitForExit(5000);
                }
            }
            catch (Exception error)
            {
                LogService("Falha ao encerrar a API: " + error.Message);
            }
            finally
            {
                process.Dispose();
            }
        }

        private void OnNodeOutput(object sender, DataReceivedEventArgs args)
        {
            if (!string.IsNullOrEmpty(args.Data))
                LogApi("INFO", args.Data);
        }

        private void OnNodeError(object sender, DataReceivedEventArgs args)
        {
            if (!string.IsNullOrEmpty(args.Data))
                LogApi("ERRO", args.Data);
        }

        private void OnNodeExited(object sender, EventArgs args)
        {
            Process process = sender as Process;
            int exitCode = -1;

            try
            {
                if (process != null)
                    exitCode = process.ExitCode;
            }
            catch
            {
            }

            lock (sync)
            {
                if (ReferenceEquals(nodeProcess, process))
                    nodeProcess = null;
            }

            LogService("A API foi encerrada com código " + exitCode + ".");

            if (stopping || Interlocked.Exchange(ref restartScheduled, 1) != 0)
                return;

            ThreadPool.QueueUserWorkItem(delegate
            {
                try
                {
                    Thread.Sleep(5000);
                    if (!stopping)
                    {
                        LogService("Tentando reiniciar a API.");
                        StartNode();
                    }
                }
                catch (Exception error)
                {
                    LogService("Falha ao reiniciar a API: " + error.Message);
                }
                finally
                {
                    Interlocked.Exchange(ref restartScheduled, 0);
                }
            });
        }

        private void LogService(string message)
        {
            WriteLog(ServiceLogPath, message);
        }

        private void LogApi(string level, string message)
        {
            WriteLog(ApiLogPath, "[" + level + "] " + message);
        }

        private void WriteLog(string path, string message)
        {
            try
            {
                lock (sync)
                {
                    Directory.CreateDirectory(Path.GetDirectoryName(path));
                    File.AppendAllText(
                        path,
                        DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " " + message + Environment.NewLine,
                        new UTF8Encoding(false));
                }
            }
            catch
            {
            }
        }

        internal void RunInConsole()
        {
            OnStart(new string[0]);
            Console.WriteLine("Sensor Delivery API em execução. Pressione ENTER para encerrar.");
            Console.ReadLine();
            OnStop();
        }
    }

    internal static class Program
    {
        private static void Main(string[] args)
        {
            SensorDeliveryApiService service = new SensorDeliveryApiService();

            if (Environment.UserInteractive && args.Length > 0 &&
                string.Equals(args[0], "--console", StringComparison.OrdinalIgnoreCase))
            {
                service.RunInConsole();
                return;
            }

            ServiceBase.Run(service);
        }
    }
}
