#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""
Creates weekly raw_crash and processed_crash tables for the last 8 weeks plus the next 2
weeks based on today.

Usage:

    python docker/create_weekly_tables.py


NOTE(willkg): This can go away as soon as we're not using postgres as a crashstorage system.

"""

import datetime
import os
import sys

import psycopg2


def get_connection():
    """Builds a connection using ConnectionContext environment variables

    :returns: postgres connection

    """
    # This uses the same environment variables and defaults as postgres ConnectionContext
    host = os.environ.get('resource.postgresql.database_hostname', 'localhost')
    port = int(os.environ.get('resource.postgresql.database_port', '5432'))
    username = os.environ.get('secrets.postgresql.database_username', 'breakpad_rw')
    password = os.environ.get('secrets.postgresql.database_password', 'aPassword')
    dbname = os.environ.get('resource.postgresql.database_name', 'breakpad')

    local_config = {
        'database_hostname': host,
        'database_port': port,
        'database_username': username,
        'database_password': password,
        'database_name': dbname
    }
    dsn = (
        "host=%(database_hostname)s "
        "dbname=%(database_name)s "
        "port=%(database_port)s "
        "user=%(database_username)s "
        "password=%(database_password)s"
    ) % local_config
    return psycopg2.connect(dsn)


def main(args):
    today = datetime.datetime.utcnow()
    eight_weeks_ago = today - datetime.timedelta(days=(7 * 8))

    conn = get_connection()
    cursor = conn.cursor()

    # This starts 8 weeks ago and tells the procedure to make 10 weeks worth of tables. So that
    # covers 8 weeks ago up to 2 weeks from now. That should be sufficient for any kinds of
    # debugging we're doing.
    cursor.callproc('weekly_report_partitions', [10, eight_weeks_ago.strftime('%Y-%m-%d')])


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
