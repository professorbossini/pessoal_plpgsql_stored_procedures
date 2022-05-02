---------------------------------------------------------------------------------------------------
-- cadastro de cliente
-- se um parâmetro com valor DEFAULT é especificado, aqueles que aparecem depois dele também deve ter valor DEFAULT
CREATE OR REPLACE PROCEDURE sp_cadastrar_cliente (IN nome VARCHAR(200), IN codigo INT DEFAULT NULL)
LANGUAGE plpgsql
AS $$
BEGIN
	IF codigo IS NULL THEN
		INSERT INTO tb_cliente (nome) VALUES (nome);
	ELSE
		INSERT INTO tb_cliente (codigo, nome) VALUES (codigo, nome);
	END IF;
END;
$$
CALL sp_cadastrar_cliente ('João da Silva');
CALL sp_cadastrar_cliente ('Maria Santos');
SELECT * FROM tb_cliente;
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- criar um pedido, como se o cliente entrasse no restaurante e pegasse a comanda
CREATE OR REPLACE PROCEDURE sp_criar_pedido (OUT cod_pedido INT, cod_cliente INT)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO tb_pedido (cod_cliente) VALUES (cod_cliente);
	-- obtém o último valor gerado por SERIAL
	SELECT LASTVAL() INTO cod_pedido;
END;
$$

DO
$$
DECLARE
	--para guardar o código de pedido gerado
	cod_pedido INT;
	-- o código do cliente que vai fazer o pedido
	cod_cliente INT;
BEGIN
	-- pega o código da pessoa cujo nome é "João da Silva"
	SELECT c.cod_cliente FROM tb_cliente c WHERE nome LIKE 'João da Silva' INTO cod_cliente;
	--cria o pedido
	CALL sp_criar_pedido (cod_pedido, cod_cliente);
	RAISE NOTICE 'Código do pedido recém criado: %', cod_pedido;
	
END;
$$
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- adicionar um item a um pedido
CREATE OR REPLACE PROCEDURE sp_adicionar_item_a_pedido (IN cod_item INT, IN cod_pedido INT)
LANGUAGE plpgsql
AS $$
BEGIN
	--insere novo item
	INSERT INTO tb_item_pedido (cod_item, cod_pedido) VALUES ($1, $2);
	--atualiza data de modificação do pedido
	UPDATE tb_pedido p SET data_modificacao = CURRENT_TIMESTAMP WHERE p.cod_pedido = $2;
END;
$$

CALL sp_adicionar_item_a_pedido (1, 1);
SELECT * FROM tb_item_pedido;
SELECT * FROM tb_pedido;
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
--calcular valor total de um pedido
DROP PROCEDURE sp_calcular_valor_de_um_pedido;
CREATE OR REPLACE PROCEDURE sp_calcular_valor_de_um_pedido (IN p_cod_pedido INT, OUT valor_total INT)
LANGUAGE plpgsql
AS $$
BEGIN
	SELECT SUM(valor) FROM
		tb_pedido p
		INNER JOIN tb_item_pedido ip ON
		p.cod_pedido = ip.cod_pedido
		INNER JOIN tb_item i ON
		i.cod_item = ip.cod_item
		WHERE p.cod_pedido = $1
		INTO $2;
END;
$$

DO $$
DECLARE
	valor_total INT; 
BEGIN
	CALL sp_calcular_valor_de_um_pedido(1, valor_total);
	RAISE NOTICE 'Total do pedido %: R$%', 1, valor_total;
	
END;
$$
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
--fechar a conta
CREATE OR REPLACE PROCEDURE sp_fechar_pedido (IN valor_a_pagar INT, IN cod_pedido INT)
LANGUAGE plpgsql
AS $$
DECLARE
	valor_total INT;
BEGIN
	--vamos verificar se o valor_a_pagar é suficiente
	CALL sp_calcular_valor_de_um_pedido (cod_pedido, valor_total);
	IF valor_a_pagar < valor_total THEN
		RAISE 'R$% insuficiente para pagar a conta de R$%', valor_a_pagar, valor_total;
	ELSE
		UPDATE tb_pedido p SET
		data_modificacao = CURRENT_TIMESTAMP,
		status = 'fechado'
		WHERE p.cod_pedido = $2;
	END IF;
END;
$$

DO $$
BEGIN
	CALL sp_fechar_pedido(200, 1);
END;
$$
SELECT * FROM tb_pedido;
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- calcular troco
CREATE OR REPLACE PROCEDURE sp_calcular_troco (OUT troco INT, IN valor_a_pagar INT, IN valor_total INT)
LANGUAGE plpgsql
AS $$
BEGIN
	troco := valor_a_pagar - valor_total;
END;
$$

DO
$$
DECLARE
 troco INT;
 valor_total INT;
 valor_a_pagar INT := 100;
BEGIN
	CALL sp_calcular_valor_de_um_pedido(1, valor_total);
	CALL sp_calcular_troco (troco, valor_a_pagar, valor_total);
	RAISE NOTICE 'A conta foi de R$% e você pagou %, portanto, seu troco é de R$%.', valor_total, valor_a_pagar, troco; 
END;
$$
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
--obter notas para o troco
CREATE OR REPLACE PROCEDURE sp_obter_notas_para_compor_o_troco (OUT resultado VARCHAR(500), IN troco INT)
LANGUAGE plpgsql
AS $$
DECLARE
	notas200 INT := 0;
	notas100 INT := 0;
	notas50 INT := 0;
	notas20 INT := 0;
	notas10 INT := 0;
	notas5 INT := 0;
	notas2 INT := 0;
	moedas1 INT := 0;
BEGIN
	notas200 := troco / 200;
	notas100 := troco % 200 / 100;
	notas50 := troco % 200 % 100 / 50;
	notas20 := troco % 200 % 100 % 50 / 20;
	notas10 := troco % 200 % 100 % 50 % 20 / 10;
	notas5 := troco % 200 % 100 % 50 % 20 % 10 / 5;
	notas2 := troco % 200 % 100 % 50 % 20 % 10 % 5 / 2;
	moedas1 := troco % 200 % 100 % 50 % 20 % 10 % 5 % 2;
	resultado := concat (
		-- E é de escape. Para que \n tenha sentido
		-- || é um operador de concatenação
		'Notas de 200: ',
		notas200 || E'\n',
		'Notas de 100: ',
		notas100 || E'\n',
		'Notas de 50: ',
		notas50 || E'\n',
		'Notas de 20: ',
		notas20 || E'\n',
		'Notas de 10: ',
		notas10 || E'\n',
		'Notas de 5: ',
		notas5 || E'\n',
		'Notas de 2: ',
		notas2 || E'\n',
		'Moedas de 1: ',
		moedas1 || E'\n'
	);
END;
$$

DO
$$
DECLARE
	resultado VARCHAR(500);
	troco INT := 43;
BEGIN
	CALL sp_obter_notas_para_compor_o_troco (resultado, troco);
	RAISE NOTICE '%', resultado;
END;
$$
---------------------------------------------------------------------------------------------------
--inserção de múltiplos clientes com VARIADIC
CREATE OR REPLACE PROCEDURE sp_cadastrar_clientes (OUT resultado TEXT, VARIADIC nomes TEXT[])
LANGUAGE plpgsql
AS $$
DECLARE
	nome TEXT;
BEGIN
	resultado := 'Clientes cadastrados: ';
	FOREACH nome IN ARRAY nomes LOOP
		INSERT INTO tb_cliente (nome) VALUES (nome);
		resultado := CONCAT (resultado, nome, ' ');
	END LOOP;
END;
$$

DO
$$
DECLARE
	resultado TEXT;
BEGIN
	CALL sp_cadastrar_clientes (resultado, 'João', 'Maria');
	RAISE NOTICE '%', resultado;
END;
$$
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
DROP TABLE tb_cliente;
CREATE TABLE tb_cliente (
	cod_cliente SERIAL PRIMARY KEY,
	nome VARCHAR(200) NOT NULL
);


SELECT * FROM tb_pedido;
DROP TABLE tb_pedido;
CREATE TABLE IF NOT EXISTS tb_pedido(
	cod_pedido SERIAL PRIMARY KEY,
	data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	data_modificacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	status VARCHAR DEFAULT 'aberto',
	cod_cliente INT NOT NULL,
	CONSTRAINT fk_cliente FOREIGN KEY (cod_cliente) REFERENCES tb_cliente(cod_cliente)
);

DROP TABLE tb_tipo_item;
CREATE TABLE tb_tipo_item(
	cod_tipo SERIAL PRIMARY KEY,
	descricao VARCHAR(200) NOT NULL
);
INSERT INTO tb_tipo_item (descricao) VALUES ('Bebida'), ('Comida');
SELECT * FROM tb_tipo_item;

DROP TABLE tb_item;
CREATE TABLE IF NOT EXISTS tb_item(
	cod_item SERIAL PRIMARY KEY,
	descricao VARCHAR(200) NOT NULL,
	valor NUMERIC (10, 2) NOT NULL,
	cod_tipo INT NOT NULL,
	CONSTRAINT fk_tipo_item FOREIGN KEY (cod_tipo) REFERENCES tb_tipo_item(cod_tipo)
);

INSERT INTO tb_item (descricao, valor, cod_tipo) VALUES
('Refrigerante', 7, 1), ('Suco', 8, 1), ('Hamburguer', 12, 2), ('Batata frita', 9, 2);
SELECT * FROM tb_item;

DROP TABLE tb_item_pedido;
CREATE TABLE IF NOT EXISTS tb_item_pedido(
	--surrogate key, assim cod_item pode repetir
	cod_item_pedido SERIAL PRIMARY KEY,
	cod_item INT,
	cod_pedido INT,
	CONSTRAINT fk_item FOREIGN KEY (cod_item) REFERENCES tb_item (cod_item),
	CONSTRAINT fk_pedido FOREIGN KEY (cod_pedido) REFERENCES tb_pedido (cod_pedido)
);