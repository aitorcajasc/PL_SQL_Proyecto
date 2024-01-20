--EJERCICIO 1
--Crear tablas y relacionarlas
drop table alumnos cascade constraints;
drop table profesores cascade constraints;
drop table incidencias cascade constraints;
drop table partes cascade constraints;

CREATE TABLE alumnos (
    cod_alumno NUMBER(5) NOT NULL,
    nom_alumno VARCHAR2(30) NOT NULL,
    ape_alumn VARCHAR(40) NOT NULL,
    PRIMARY KEY (cod_alumno)
);

CREATE TABLE profesores (
    cod_profesor NUMBER(5) NOT NULL,
    nom_profesor VARCHAR2(30) NOT NULL,
    PRIMARY KEY (cod_profesor)
);

CREATE TABLE incidencias (
    cod_incidencia NUMBER(*, 0) NOT NULL,
    nom_incidencia VARCHAR2(100) NOT NULL,
    PRIMARY KEY (cod_incidencia)
);

CREATE TABLE partes (
    cod_parte NUMBER(5) NOT NULL,
    cod_profesor NUMBER(5) NOT NULL,
    cod_alumno NUMBER(5) NOT NULL,
    cod_incidencia NUMBER(5) NOT NULL,
    fecha_parte DATE,
    PRIMARY KEY (cod_parte),
    FOREIGN KEY (cod_profesor) REFERENCES profesores,
    FOREIGN KEY (cod_alumno) REFERENCES alumnos,
    FOREIGN KEY (cod_incidencia) REFERENCES incidencias
);

--Modificar tabla añadiendo un campo nuevo
ALTER TABLE profesores
ADD ape_profesor VARCHAR2(30) NOT NULL;

--EJERCICIO 2
--Crear tabla
CREATE TABLE audita_reservas(info VARCHAR2(1000));

--Trigger para insertar en la tabla cuando se insertan valores en la tabla pasajeros
--y se borren valores de la tabla vuelos
create or replace TRIGGER auditaReserva
AFTER INSERT OR DELETE ON reservas FOR EACH ROW
DECLARE
    nom pasajeros.nom_pasajero%TYPE;
    ape pasajeros.ape_pasajero%TYPE;
    tel pasajeros.tel_pasajero%TYPE;
    
    origen vuelos.origen_vuelo%TYPE;
    destino vuelos.destino_vuelo%TYPE;
    fecha vuelos.fecha_vuelo%TYPE;
    hora vuelos.hora_vuelo%TYPE;
BEGIN
    IF INSERTING THEN
        SELECT nom_pasajero, ape_pasajero, tel_pasajero
        INTO nom, ape, tel
        FROM pasajeros WHERE cod_pasajero=:NEW.cod_pasajero;
    
        INSERT INTO audita_reservas VALUES(
        'Se ha relizado una insercci�n, realizada por el usuario "'||USER||
        '", en la fecha '||TO_CHAR(SYSDATE, 'DD/MM/YYYY')||', el nombre del
        pasajero es '||nom||' '||ape||' con tel�fono: '||tel);
    END IF;
    
    IF DELETING THEN
        SELECT origen_vuelo, destino_vuelo, fecha_vuelo, hora_vuelo
        INTO origen, destino, fecha, hora
        FROM vuelos WHERE cod_vuelo=:OLD.cod_vuelo;
    
        INSERT INTO audita_reservas VALUES(
        'Se ha borrado un registro, realizado por el usuario "'||USER||
        '", en la fecha '||TO_CHAR(SYSDATE, 'DD/MM/YYYY')||', el origen del
        vuelo era '||origen||' con destino a '||destino||' el d�a 
        '||TO_CHAR(fecha, 'DD/MM/YYYY')||' a las '||hora);
    END IF;
END;

--Comrprobar que el Trigger funciona
INSERT INTO reservas VALUES(5, 11, 9, 999);
DELETE FROM reservas WHERE cod_vuelo=4 AND cod_pasajero=10;

--EJERCICIO 3
--Funcion para validar que el pasajero existe en la base de datos
CREATE OR REPLACE FUNCTION validarCodPasaj(
    cpasaj pasajeros.cod_pasajero%TYPE) RETURN NUMBER IS
    
    aux pasajeros.cod_pasajero%TYPE;
BEGIN
    SELECT cod_pasajero INTO aux FROM pasajeros
    WHERE cod_pasajero=cpasaj;
    
    RETURN aux;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;

--Procedimiento para mostrar los vuelos de un pasajero
create or replace PROCEDURE mostrarVuelos(
    cpasaj pasajeros.cod_pasajero%TYPE) IS
    
    CURSOR cPasajero IS
        SELECT cod_pasajero, nom_pasajero nombre, ape_pasajero ape
        FROM pasajeros
        WHERE cod_pasajero=cpasaj;

    CURSOR cVuelo(codipasaj pasajeros.cod_pasajero%TYPE) IS
        SELECT DISTINCT origen_vuelo origen, destino_vuelo destino,
        nom_agencia nombre, precio, cod_pasajero FROM vuelos
        JOIN reservas USING(cod_vuelo)
        JOIN pasajeros USING(cod_pasajero)
        JOIN agencias USING(cod_agencia)
        WHERE cod_pasajero=codipasaj;

    contR NUMBER(8):=0;
    tPrecio NUMBER(8):=0;
BEGIN
    FOR i IN cPasajero LOOP
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('NOMBRE PASAJERO: '||i.nombre||' '||i.ape);
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('ORIGEN          DESTINO          AGENCIA          PRECIO');
        
        contR:=0;
        tPrecio:=0;
        FOR j IN cVuelo(i.cod_pasajero) LOOP
            SELECT COUNT(DISTINCT cod_vuelo), SUM(DISTINCT precio)
            INTO contR, tPrecio
            FROM reservas
            WHERE cod_pasajero=i.cod_pasajero;

            DBMS_OUTPUT.PUT_LINE(RPAD(j.origen, 16)||
            RPAD(j.destino, 17)||RPAD(j.nombre, 17)||TO_CHAR(j.precio)||'�');
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('N�MERO DE RESERVAS: '||TO_CHAR(contR)||'   TOTAL PRECIO RESERVAS: '||tPrecio||'�');
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    END LOOP;
END;

--Bloque de PL para comprobar que la función y el procedimiento funcionan
DECLARE
    cpasaj pasajeros.cod_pasajero%TYPE:=&codigo_pasajero;
    aux pasajeros.cod_pasajero%TYPE;
BEGIN
    aux:=validarCodPasaj(cpasaj);
    
    IF aux!=0 THEN
        mostrarVuelos(aux);
    ELSE
        DBMS_OUTPUT.PUT_LINE('El c�digo de pasajero no existe socio');
    END IF;
END;

--EJERCICIO 4
--Procedimiento para mostrar los aviones que hay en la base de datos por línea aérea
create or replace PROCEDURE mostrarDatosVuelos(
    clinea lineas_aereas.cod_linea%TYPE) IS
    
    CURSOR cLinea_aerea IS
        SELECT nom_linea, cod_linea FROM lineas_aereas
        WHERE cod_linea=clinea;

    CURSOR cAvion(codigo_linea lineas_aereas.cod_linea%TYPE) IS
        SELECT cod_avion, nom_avion, modelo_avion FROM aviones
        WHERE cod_linea=codigo_linea;

    CURSOR cVuelo(cavion aviones.cod_avion%TYPE) IS
        SELECT origen_vuelo origen, destino_vuelo destino,
        fecha_vuelo fecha FROM vuelos
        WHERE cod_avion=cavion;

    contador NUMBER(8);
BEGIN
    FOR i IN cLinea_aerea LOOP
        DBMS_OUTPUT.PUT_LINE('NOMBRE DE LA L�NEA: '||i.nom_linea);
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------');

        FOR j IN cAvion(i.cod_linea) LOOP
            DBMS_OUTPUT.PUT_LINE('NOMBRE AVI�N: '||j.nom_avion||'     MODELO AVI�N: '||j.modelo_avion);
            DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------');
            DBMS_OUTPUT.PUT_LINE('ORIGEN          DESTINO          FECHA VUELO');

            contador:=0;
            FOR k IN cVuelo(j.cod_avion) LOOP
                DBMS_OUTPUT.PUT_LINE(RPAD(k.origen, 16)||
                RPAD(k.destino, 17)||k.fecha);

                SELECT COUNT(*) INTO contador FROM vuelos
                WHERE cod_avion=j.cod_avion;
            END LOOP;

            DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------');
            DBMS_OUTPUT.PUT_LINE('                             N�MERO VUELOS AVI�N: '||TO_CHAR(contador));
            DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------');
        END LOOP;
    END LOOP;
END;

--Bloque de PL que demuestre el funcionamiento del procedimiento
SET SERVEROUTPUT ON
DECLARE
    clinea lineas_aereas.cod_linea%TYPE:=&codigo_linea;
BEGIN
    mostrarDatosVuelos(clinea);
END;