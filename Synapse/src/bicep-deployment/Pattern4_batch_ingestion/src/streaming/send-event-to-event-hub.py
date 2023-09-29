

import time
import asyncio
import os
from dotenv import load_dotenv
from datetime import datetime
import uuid
import json

load_dotenv()

from azure.eventhub.aio import EventHubProducerClient
from azure.eventhub.exceptions import EventHubError
from azure.eventhub import EventData

CONNECTION_STR = os.environ['EVENT_HUB_CONN_STR']
EVENTHUB_NAME = os.environ['EVENT_HUB_NAME']



async def run():
    # Create a producer client to send messages to the event hub.
    # Specify a connection string to your event hubs namespace and
    # the event hub name.
    producer = EventHubProducerClient.from_connection_string(conn_str=CONNECTION_STR, eventhub_name=EVENTHUB_NAME)
    async with producer:
     
        event_data_list = [EventData('Event Data {}'.format(i)) for i in range(10)]
        
        event_data_batch = await producer.create_batch()
        event_data_batch = await producer.create_batch()
        for i in range(1,50):
            # event_data = EventData(f'Message with properties seq: {i}')
            # event_data.properties = {f'prop_key': f'prop_value{i}'}
            now = datetime.now()
            device = {}
            device["id"] = str(uuid.uuid4())
            device["timestamp"] = str(now)
           
            body1 = json.dumps(device)
            event_data = EventData(body1)
            print(event_data)
            event_data_batch.add(event_data)

        # for event_data in event_data_batch:
        #     print(event_data)
        try:
            await producer.send_batch(event_data_batch)
        except ValueError:  # Size exceeds limit. This shouldn't happen if you make sure before hand.
            print("Size of the event data list exceeds the size limit of a single send")
        except EventHubError as eh_err:
            print("Sending error: ", eh_err)

loop = asyncio.get_event_loop()
loop.run_until_complete(run())