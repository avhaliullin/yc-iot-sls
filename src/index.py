import base64
import json
import logging
from logging.config import dictConfig

with open('log-config.json') as f:
    dictConfig(json.loads(f.read()))

_LOGGER = logging.getLogger(__name__)


def handler(event, context):
    for msg in event['messages']:
        details = msg['details']
        device_id = details['device_id']
        payload = base64.b64decode(details['payload']).decode('utf-8')
        _LOGGER.info(f'Received message {payload} from device {device_id}')

    return ''