CREATE OR REPLACE PROCEDURE sp_calcula_media ( VARIADIC  valores INT [])
LANGUAGE plpgsql
AS $$
DECLARE
	media NUMERIC(10, 2) := 0;
	valor INT;
	
BEGIN
	FOREACH valor IN ARRAY valores LOOP
		media := media + valor;	
	END LOOP;
	--array_length calcula o número de elementos no array. O segundo parâmetro é o número de dimensões dele
	RAISE NOTICE 'A média é %', media / array_length(valores, 1);
END;
$$

-- 1 parâmetro
CALL sp_calcula_media(1);

-- 2 parâmetros
CALL sp_calcula_media(1, 2);

-- 6 parâmetros
CALL sp_calcula_media(1, 2, 5, 6, 1, 8);

-- não funciona
CALL sp_calcula_media (ARRAY[1, 2]);




DROP PROCEDURE IF EXISTS sp_acha_maior;
-- criando
CREATE OR REPLACE PROCEDURE sp_acha_maior (INOUT valor1 INT, IN valor2 INT)
LANGUAGE plpgsql
AS $$
BEGIN
	IF valor2 > valor1 THEN
 		valor1 := valor2;
	END IF;
END;
$$

-- colocando em execução
DO
$$
DECLARE
	valor1 INT := 2;
	valor2 INT := 3;
	
BEGIN
	CALL sp_acha_maior(valor1, valor2);
	RAISE NOTICE '% é o maior', valor1;
END;
$$

-- aqui estamos removendo o proc de nome sp_acha_maior para poder reutilizar o nome
DROP PROCEDURE IF EXISTS sp_acha_maior;
CREATE OR REPLACE PROCEDURE sp_acha_maior (OUT resultado INT, IN valor1 INT, IN valor2 INT)
LANGUAGE plpgsql
AS $$
BEGIN
	CASE
		WHEN valor1 > valor2 THEN
			$1 := valor1;
		ELSE
			resultado := valor2;
	END CASE;
END;
$$

--colocando em execução
DO $$
DECLARE
	resultado INT;
BEGIN
	CALL sp_acha_maior (resultado, 2, 3);
	RAISE NOTICE '% é o maior', resultado;
END;
$$
--criando
--ambos são IN, pois IN é o padrão
CREATE OR REPLACE PROCEDURE sp_acha_maior (IN valor1 INT, valor2 INT)
LANGUAGE plpgsql
AS $$
BEGIN
	IF valor1 > valor2 THEN
		RAISE NOTICE '% é o maior', $1;
	ELSE
		RAISE NOTICE '% é o maior', $2;
	END IF;
END;
$$

-- colocando em execução
CALL sp_acha_maior (2, 3);


-- criando
CREATE OR REPLACE PROCEDURE sp_ola_usuario (nome VARCHAR(200))
LANGUAGE plpgsql
AS $$
BEGIN
	-- acessando parâmetro pelo nome
	RAISE NOTICE 'Olá, %', nome;
	-- assim também vale
	RAISE NOTICE 'Olá, %', $1;
END;
$$;

--colocando em execução
CALL sp_ola_usuario('Pedro');
