from uuid import uuid4
from flask import current_app

import numpy as np
import pandas as pd

from geonature.utils.env import DB

from .utils import (
    fill_col,
    fill_map,
    set_is_valid,
    set_error_and_invalid_reason,
    set_warning_reason,
)
from ..wrappers import checker
from ..logs import logger
from ..db.queries.user_table_queries import get_uuid_list
from ..utils.utils import create_col_name

import pdb


def fill_nan_uuid(value):
    if pd.isnull(value):
        return str(uuid4())
    else:
        return value


@checker("Data cleaning : uuid values checked")
def check_uuid(
    df, selected_columns, synthese_info, is_generate_uuid, import_id, schema_name,
):

    try:

        # send warnings if some uuid are missing :

        logger.info("CHECKING UUID VALUES")

        uuid_cols = [
            field
            for field in synthese_info
            if synthese_info[field]["data_type"] == "uuid"
        ]
        if len(uuid_cols) > 0:

            for col in uuid_cols:
                # localize null values
                df["temp"] = ""
                df["temp"] = (
                    df["temp"]
                    .where(cond=df[selected_columns[col]].notnull(), other=False)
                    .map(fill_map)
                    .astype("bool")
                )

                # df['gn_is_valid'] = df['gn_is_valid'].where(cond=df['temp'].apply(lambda x: fill_col(x)), other=False)

                if col == "unique_id_sinp":

                    uuid_col_name = selected_columns[col]

                    # check duplicates in user file
                    logger.info(
                        "- checking duplicates in unique_id_sinp column (= %s user column)",
                        uuid_col_name,
                    )
                    # remove NaN value to apply a .str
                    df[uuid_col_name] = df[uuid_col_name].fillna("")
                    df["temp"] = df[uuid_col_name].str.lower().duplicated(keep=False)
                    df["temp"] = (
                        df["temp"]
                        .where(
                            cond=df[uuid_col_name].isnull() | df[uuid_col_name] == "",
                            other=False,
                        )
                        .map(fill_map)
                        .astype("bool")
                    )
                    df["temp2"] = ~df["temp"].astype("bool")

                    set_is_valid(df, "temp2")
                    id_rows_errors = df.index[df["temp2"] == False].to_list()

                    logger.info(
                        "%s duplicates errors in unique_id_sinp column (= %s user column)",
                        len(id_rows_errors),
                        uuid_col_name,
                    )

                    if len(id_rows_errors) > 0:
                        set_error_and_invalid_reason(
                            df=df,
                            id_import=import_id,
                            error_code="DUPLICATE_UUID",
                            col_name_error=uuid_col_name,
                            df_col_name_valid="temp2",
                            id_rows_error=id_rows_errors,
                        )

                    # if unique_id_sinp col provided, uuid value created if any missing field:
                    if df[selected_columns[col]].isnull().any():
                        if is_generate_uuid:
                            logger.info(
                                "generating uuid for missing values in %s synthese column (= %s user column)",
                                col,
                                selected_columns[col],
                            )
                            create_col_name(df, selected_columns, col, import_id)
                            df[selected_columns[col]] = ""
                            df[selected_columns[col]] = df[uuid_col_name].apply(
                                lambda x: fill_nan_uuid(x)
                            )
                            set_warning_reason(
                                df,
                                "temp",
                                "warning: missing uuid: {} column: autogenerated",
                                uuid_col_name,
                            )

                    # return False if invalid uuid, else (including missing values) return True
                    if current_app.config["IMPORT"]["ENABLE_SYNTHESE_UUID_CHECK"]:
                        uuid_list = get_uuid_list()
                        df["temp"] = ""
                        df["temp"] = (
                            df["temp"]
                            .where(
                                cond=df[selected_columns[col]].isin(uuid_list),
                                other=False,
                            )
                            .map(fill_map)
                            .astype("bool")
                        )
                        df["temp"] = ~df["temp"]

                        set_is_valid(df, "temp")
                        id_rows_errors = df.index[df["temp"] == False].to_list()

                        logger.info(
                            "%s uuid value exists already in synthese table (= %s user column)",
                            len(id_rows_errors),
                            selected_columns[col],
                        )

                        if len(id_rows_errors) > 0:
                            set_error_and_invalid_reason(
                                df=df,
                                id_import=import_id,
                                error_code="EXISTING_UUID",
                                col_name_error=uuid_col_name,
                                df_col_name_valid="temp",
                                id_rows_error=id_rows_errors,
                            )

                # pour les autres colonnes : on envoie un warning sans créer un uuid pour les champs manquants:
                else:
                    logger.info(
                        "check for missing values in %s synthese column (= %s user column)",
                        col,
                        selected_columns[col],
                    )

                    df["gn_invalid_reason"] = df["gn_invalid_reason"].where(
                        cond=df["temp"],
                        other=df["gn_invalid_reason"]
                        + "warning: missing uuid: {} column *** ".format(
                            selected_columns[col]
                        ),
                    )

                    n_missing_uuid = df["temp"].astype(str).str.contains("False").sum()

                    logger.info(
                        "%s missing values warnings in %s synthese column (= %s user column)",
                        n_missing_uuid,
                        col,
                        selected_columns[col],
                    )

        # create unique_id_sinp column with uuid values if not existing :

        if "unique_id_sinp" not in uuid_cols:
            if is_generate_uuid:
                logger.info(
                    "no unique_id_sinp column provided: creating uuid for each row"
                )
                df["unique_id_sinp"] = ""
                df["unique_id_sinp"] = df["unique_id_sinp"].apply(
                    lambda x: str(uuid4())
                )

    except Exception:
        raise
