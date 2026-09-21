-- Garantir que a Italian Pizza use o logotipo permanente versionado
UPDATE empresas
SET logo_url = '/uploads/logo_italian_pizza.jpg'
WHERE documento = '00000000000000'
   OR nome_fantasia ILIKE '%Italian Pizza%'
   OR razao_social ILIKE '%Pizzaria Almeida%';
