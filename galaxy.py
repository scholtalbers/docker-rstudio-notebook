#!/usr/bin/env python
from bioblend.galaxy import objects
import subprocess
import argparse
import os
from string import Template
import logging
DEBUG = os.environ.get('DEBUG', "False").lower() == 'true'
logging.basicConfig(level=logging.CRITICAL)
if DEBUG:
    logging.basicConfig(level=logging.DEBUG)
logging.getLogger("bioblend").setLevel(logging.CRITICAL)

log = logging.getLogger()


def get_galaxy_connection():
    """
        Given access to the configuration dict that galaxy passed us, we try and connect to galaxy's API.
        Other than the docker setup we fully rely on the proper environment setup to take the
        connection details from. In the function we might just error on an invalid connection.
    """
    key = os.environ['GX_API_KEY']
    url = os.environ['GX_URL']
    return objects.GalaxyInstance(url, key)


def get_history(gi, history_id=None):
    """
        Get the requested or current history
    """
    history_id = history_id or os.environ['GX_HISTORY_ID']

    try:
        history = gi.histories.get(history_id)
    except:
        log.critical("Could not retrieve history")
        raise
    return history


def put(filename, file_type='auto', history_id=None):
    """
        Given a filename of any file accessible, this
        function will upload that file to galaxy using the current history.
        Does not return anything.
    """
    gi = get_galaxy_connection()
    history = get_history(gi, history_id)
    try:
        history.upload_dataset(filename, file_type=file_type)
    except:
        log.critical(
            "Could not get dataset from history '{0}'({1})"
            .format(history.name, history.id)
        )
        raise


def get(dataset_id, file_path, history_id=None):
    """
        Given the history_id that is displayed to the user, this function will
        download the file from the history and stores it under the given file_path
    """
    gi = get_galaxy_connection()

    # Cache the file requests. E.g. in the example of someone doing something
    # silly like a get() for a Galaxy file in a for-loop, wouldn't want to
    # re-download every time and add that overhead.
    if not os.path.exists(file_path):
        history = get_history(gi, history_id)
        try:
            datasets = dict([(d.wrapped["hid"], d.id) for d in history.get_datasets()])
            dataset = history.get_dataset(datasets[dataset_id])
            dataset.download(open(file_path, 'wb'))
        except:
            log.critical(
                "Could not retrieve dataset '{0}' from history '{1}'({2})"
                .format(dataset_id, history.name, history.id)
            )
            raise
    return file_path


def histories():
    """
        Prints the ID and Label of all the user histories.
    """
    gi = get_galaxy_connection()
    histories = []
    try:
        # get list of histories with only the required attributes
        histories = [ [hist.id, hist.name, hist.wrapped['create_time'], hist.wrapped['update_time'] ] 
                      for hist in gi.histories.list() ]
    except:
        log.critical("Could not list histories")
        raise

    # sort by update_time
    histories.sort(key=lambda x: x[3],reverse=True)
    print("ID\tLabel\tCreated\tUpdated")
    for hist in histories:
        print("{0}\t{1}\t{2}\t{3}".format(*hist))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Connect to Galaxy through the API')
    parser.add_argument('--action',   help='Action to execute', choices=['get', 'put', 'histories'])
    parser.add_argument('--argument', help='File/ID number to Upload/Download, respectively')
    parser.add_argument(
        '--history-id', dest="history_id", default=None,
        help='History ID. The history ID and the dataset ID uniquly identify a dataset. Per default \
        this is set to the current Galaxy history.'
    )
    parser.add_argument(
        '-t', '--filetype',
        help='Galaxy file format. If not specified Galaxy will try to guess the filetype automatically.',
        default='auto'
    )
    parser.add_argument('--file-path', dest="file_path", help="The file path to work with, e.g. for get()")
    args = parser.parse_args()

    if args.action == 'get':
        # Ensure it's a numerical value
        get(int(args.argument), args.file_path, history_id=args.history_id)
    elif args.action == 'put':
        put(args.argument, file_type=args.filetype, history_id=args.history_id)
    elif args.action == 'histories':
        histories()
