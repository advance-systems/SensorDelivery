import {query} from "../../database/connection.js";
export interface Empresa{id:string;razao_social:string;nome_fantasia:string;documento:string|null;telefone:string|null;email:string|null;ativo:boolean}
export class EmpresaRepository{listar(){return query<Empresa>(`SELECT id,razao_social,nome_fantasia,documento,telefone,email,ativo FROM empresas WHERE ativo=TRUE ORDER BY nome_fantasia`)}async buscarPorId(id:string){return (await query<Empresa>(`SELECT id,razao_social,nome_fantasia,documento,telefone,email,ativo FROM empresas WHERE id=$1`,[id]))[0]??null}}
