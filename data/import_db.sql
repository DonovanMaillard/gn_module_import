SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


--------------
--GN_IMPORTS--
--------------
CREATE SCHEMA IF NOT EXISTS gn_imports;

SET search_path = gn_imports, pg_catalog;
SET default_with_oids = false;

------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_imports(
    id_import serial NOT NULL,
    format_source_file character varying(10),
    SRID integer,
    separator character varying,
    encoding character varying,
    import_table character varying(255),
    full_file_name character varying(255),
    id_dataset integer,
    id_field_mapping integer,
    id_content_mapping integer,
    date_create_import timestamp without time zone DEFAULT now(),
    date_update_import timestamp without time zone DEFAULT now(),
    date_end_import timestamp without time zone,
    source_count integer,
    import_count integer,
    taxa_count integer,
    uuid_autogenerated boolean,
    altitude_autogenerated boolean,
    date_min_data timestamp without time zone,
    date_max_data timestamp without time zone,
    step integer,
    is_finished boolean DEFAULT FALSE,
    processing boolean DEFAULT FALSE,
    in_error boolean DEFAULT FALSE
);


CREATE TABLE cor_role_import(
    id_role integer NOT NULL,
    id_import integer NOT NULL
);


CREATE TABLE t_user_errors(
    id_error serial NOT NULL,
    error_type character varying(100) NOT NULL,
    name character varying(255) NOT NULL UNIQUE,
    description text,
    error_level character varying(25)
);


CREATE TABLE cor_role_mapping(
    id_role integer NOT NULL,
    id_mapping integer NOT NULL
);


CREATE TABLE t_mappings_fields(
    id_match_fields serial NOT NULL,
    id_mapping integer NOT NULL,
    source_field character varying(255) NOT NULL,
    target_field character varying(255) NOT NULL,
    is_selected boolean NOT NULL,
    is_added boolean NOT NULL
);


CREATE TABLE t_mappings_values(
    id_match_values serial NOT NULL,
    id_mapping integer NOT NULL,
    --id_type_mapping integer NOT NULL,
    source_value character varying(255) NOT NULL,
    id_target_value integer NOT NULL
);


CREATE TABLE t_mappings(
    id_mapping serial NOT NULL,
    mapping_label character varying(255) NOT NULL,
    mapping_type character varying(10) NOT NULL,
    active boolean NOT NULL,
    temporary boolean NOT NULL DEFAULT false
);


CREATE TABLE dict_themes(
    id_theme serial,
    name_theme character varying(100) NOT NULL,
    fr_label_theme character varying(100) NOT NULL,
    eng_label_theme character varying(100),
    desc_theme character varying(1000),
    order_theme integer NOT NULL
);


CREATE TABLE dict_fields(
    id_field serial,
    name_field character varying(100) NOT NULL,
    fr_label character varying(100) NOT NULL,
    eng_label character varying(100),
    desc_field character varying(1000),
    type_field character varying(50),
    synthese_field boolean NOT NULL,
    mandatory boolean NOT NULL,
    autogenerated boolean NOT NULL,
    nomenclature boolean NOT NULL,
    id_theme integer NOT NULL,
    order_field integer NOT NULL,
    display boolean NOT NULL,
    comment text
);


CREATE TABLE cor_synthese_nomenclature(
    mnemonique character varying(50) NOT NULL,
    synthese_col character varying(50) NOT NULL
);


CREATE TABLE t_user_error_list(
    id_user_error serial NOT NULL,
    id_import integer NOT NULL,
    id_error integer NOT NULL,
    column_error character varying(100) NOT NULL,
    id_rows integer[],
    step character varying(20),
    comment text
);


CREATE VIEW gn_imports.v_imports_errors AS 
SELECT 
id_user_error,
id_import,
error_type,
name AS error_name,
error_level,
description AS error_description,
column_error,
id_rows,
comment
FROM  gn_imports.t_user_error_list el 
JOIN gn_imports.t_user_errors ue on ue.id_error = el.id_error;



----------------------------
--PRIMARY KEY AND UNICITY---
----------------------------

ALTER TABLE ONLY t_imports 
    ADD CONSTRAINT pk_gn_imports_t_imports PRIMARY KEY (id_import);

ALTER TABLE ONLY cor_role_import 
    ADD CONSTRAINT pk_cor_role_import PRIMARY KEY (id_role, id_import);

ALTER TABLE ONLY t_user_errors 
    ADD CONSTRAINT pk_user_errors PRIMARY KEY (id_error);

ALTER TABLE ONLY cor_role_mapping
    ADD CONSTRAINT pk_cor_role_mapping PRIMARY KEY (id_role, id_mapping);

ALTER TABLE ONLY t_mappings_fields
    ADD CONSTRAINT pk_t_mappings_fields PRIMARY KEY (id_match_fields);

ALTER TABLE ONLY t_mappings_values
    ADD CONSTRAINT pk_t_mappings_values PRIMARY KEY (id_match_values);

ALTER TABLE ONLY t_mappings
    ADD CONSTRAINT pk_t_mappings PRIMARY KEY (id_mapping);


--ALTER TABLE ONLY bib_type_mapping_values
--    ADD CONSTRAINT pk_bib_type_mapping_values PRIMARY KEY (id_type_mapping, mapping_type);

ALTER TABLE ONLY dict_themes
    ADD CONSTRAINT pk_dict_themes_id_theme PRIMARY KEY (id_theme);

ALTER TABLE ONLY dict_fields
    ADD CONSTRAINT pk_dict_fields_id_theme PRIMARY KEY (id_field);

ALTER TABLE ONLY dict_fields
    ADD CONSTRAINT unicity_t_mappings_fields_name_field UNIQUE (name_field);


ALTER TABLE ONLY cor_synthese_nomenclature
    ADD CONSTRAINT pk_cor_synthese_nomenclature PRIMARY KEY (mnemonique, synthese_col);

ALTER TABLE ONLY t_user_error_list
    ADD CONSTRAINT pk_t_user_error_list PRIMARY KEY (id_user_error);

---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY t_imports
    ADD CONSTRAINT fk_gn_meta_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_imports
    ADD CONSTRAINT fk_gn_imports_t_mappings_fields FOREIGN KEY (id_field_mapping) REFERENCES gn_imports.t_mappings(id_mapping) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_imports
    ADD CONSTRAINT fk_gn_import_t_mappings_values FOREIGN KEY (id_content_mapping) REFERENCES gn_imports.t_mappings(id_mapping) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_import
    ADD CONSTRAINT fk_utilisateurs_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_mapping
    ADD CONSTRAINT fk_utilisateurs_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_mapping
    ADD CONSTRAINT fk_gn_imports_t_mappings_id_mapping FOREIGN KEY (id_mapping) REFERENCES gn_imports.t_mappings(id_mapping) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_mappings_fields
    ADD CONSTRAINT fk_gn_imports_t_mappings_id_mapping FOREIGN KEY (id_mapping) REFERENCES gn_imports.t_mappings(id_mapping) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_mappings_fields
    ADD CONSTRAINT fk_gn_imports_t_mappings_fields_target_field FOREIGN KEY (target_field) REFERENCES gn_imports.dict_fields(name_field) ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE ONLY t_mappings_values
    ADD CONSTRAINT fk_gn_imports_t_mappings_id_mapping FOREIGN KEY (id_mapping) REFERENCES gn_imports.t_mappings(id_mapping) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_mappings_values
    ADD CONSTRAINT fk_gn_imports_t_mappings_values_id_nomenclature FOREIGN KEY (id_target_value) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE ON DELETE CASCADE;

--ALTER TABLE ONLY t_mappings_values
--    ADD CONSTRAINT fk_gn_imports_bib_type_mapping_values_id_type_mapping FOREIGN KEY (id_type_mapping) REFERENCES gn_imports.bib_type_mapping_values(id_type_mapping) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY dict_fields
    ADD CONSTRAINT fk_gn_imports_dict_themes_id_theme FOREIGN KEY (id_theme) REFERENCES gn_imports.dict_themes(id_theme) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_synthese_nomenclature
    ADD CONSTRAINT fk_cor_synthese_nomenclature_id_type FOREIGN KEY (mnemonique) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_user_error_list
    ADD CONSTRAINT fk_t_user_error_list_id_import FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_user_error_list
    ADD CONSTRAINT fk_t_user_error_list_id_error FOREIGN KEY (id_error) REFERENCES gn_imports.t_user_errors(id_error) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_import
    ADD CONSTRAINT fk_cor_role_import_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;
    
 ALTER TABLE ONLY cor_role_import
 ADD CONSTRAINT fk_cor_role_import_import FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE ON DELETE CASCADE;

---------------------
--OTHER CONSTRAINTS--
---------------------

ALTER TABLE ONLY t_mappings
   ADD CONSTRAINT check_mapping_type_in_t_mappings CHECK (mapping_type IN ('FIELD', 'CONTENT'));

ALTER TABLE ONLY dict_fields
    ADD CONSTRAINT chk_mandatory CHECK (
    CASE
        WHEN name_field IN ('date_min', 'longitude', 'latitude', 'nom_cite', 'cd_nom', 'wkt') 
        THEN mandatory=TRUE
    END
);

------------
--TRIGGERS--
------------
-- faire un trigger pour cor_role_mapping qui rempli quand create ou delete t_mappings.id_mapping?



-------------
--FUNCTIONS--
-------------

                                                                           
-----------------------
--GN_IMPORTS_ARCHIVES--
-----------------------

CREATE SCHEMA gn_import_archives;


SET search_path = gn_import_archives, pg_catalog;
SET default_with_oids = false;


----------
--TABLES--
----------

CREATE TABLE cor_import_archives(
  id_import integer NOT NULL,
  table_archive character varying(255) NOT NULL
);


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY cor_import_archives ADD CONSTRAINT pk_cor_import_archives PRIMARY KEY (id_import, table_archive);


---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY cor_import_archives
    ADD CONSTRAINT fk_gn_imports_t_imports FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE ON DELETE CASCADE;


------------
--TRIGGERS--
------------

-- faire trigger pour rappatrier données dans cor_import_archives quand creation dun nouvel import?


-------------
--FUNCTIONS--
-------------


