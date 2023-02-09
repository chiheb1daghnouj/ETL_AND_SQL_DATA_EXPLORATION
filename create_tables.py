import pandas as pd
import psycopg2
import os
import glob
from sqlalchemy import create_engine


def create_database():
    # connexion to default db : postgres
    conn = psycopg2.connect(host='127.0.0.1', user='postgres', dbname='postgres', password='CHiheb 10')
    conn.set_session(autocommit=True)
    cur = conn.cursor()

    # create new db : sparkifydb
    cur.execute("DROP DATABASE if EXISTS covid_project;")
    cur.execute("CREATE DATABASE covid_project with ENCODING 'utf8' TEMPLATE template0")
    conn.commit()

    # close connexion to default database
    conn.close()
    # connexion to new db : covid_project
    conn = psycopg2.connect(host='127.0.0.1', user='postgres', dbname='covid_project', password='CHiheb 10')
    conn.set_session(autocommit=True)
    cur = conn.cursor()
    return conn, cur


def find_excel_files(path):
    """
    :param path: repository path
    :return: paths of all excel files in repository
    """
    all_files = []
    for root, dirs, files in os.walk(path):
        files = glob.glob(os.path.join(root, '*.xlsx'))
        for f in files:
            all_files.append(os.path.abspath(f))
    print('{} excel files are found in {}'.format(len(all_files), path))
    return all_files


def file_2_table(files):
    """
    :param files: excel files paths
    :return: create table from each file
    """
    conn_string = 'postgresql://postgres:CHiheb 10@localhost:5432/covid_project'
    db = create_engine(conn_string)
    conn = db.connect()
    for i, f in enumerate(files):
        # create table from each excel file
        name = f.split('/')[-1].split('.')[0]
        data = pd.read_excel(f)
        # fill table with excel file data
        data.to_sql('table{}'.format(i), con=conn, if_exists='replace', index=False)
    conn.close()


if __name__ == '__main__':
    conn, cur = create_database()
    path = '/home/chiheb/PycharmProjects/portfolio/SQL_data_exploration/data'
    files = find_excel_files(path)
    file_2_table(files)
