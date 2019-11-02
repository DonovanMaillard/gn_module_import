from ...db.queries.load_to_synthese import get_data_type, insert_into_synthese


def load_data_to_synthese(schema_name, table_name, total_columns):
    try:

        # add key type info to value ('value::type')
        select_part = []
        for key, value in total_columns.items():
            if key == 'the_geom_4326':
                key_type = 'geometry(Geometry,4326)'
            elif key == 'the_geom_point':
                key_type = 'geometry(Point,4326)'
            elif key == 'the_geom_local':
                key_type = 'geometry(Geometry,2154)'
            else:
                key_type = get_data_type(key)
            select_part.append('::'.join([str(value), key_type]))

        # insert into t_source

        # insert into synthese
        insert_into_synthese(schema_name, table_name, select_part, total_columns)
        DB.session.commit()

    except Exception:
        DB.session.rollback()
        raise