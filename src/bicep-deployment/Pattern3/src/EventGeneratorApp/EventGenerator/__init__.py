import logging
import time
import os
import uuid
import datetime
import random
import json
from dotenv import load_dotenv
from azure.eventhub import EventHubProducerClient, EventData

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python EventGenerator function processed a request.')
    CONNECTION_STR = os.environ['EVENT_HUB_CONN_STR_SYNAPSESTREAMING']
    EVENTHUB_NAME = os.environ['EVENT_HUB_NAME_SYNAPSESTREAMING']
    # print(CONNECTION_STR)
    # print(EVENTHUB_NAME)

    # first check if the value is present in the query parameter or not. 
    number_of_events = req.params.get('number_of_events')
    if number_of_events:
        print(number_of_events)
        print(f"number_of_events:: {number_of_events}")
        number_of_devices = int(int(number_of_events)/20)
        print(f"number_of_devices:: {number_of_devices}")

    if not number_of_events:
        try:
            req_body = req.get_json()
        except ValueError: # If no body is present
            number_of_events=100
            number_of_devices=5
        else:
            number_of_events = req_body.get('number_of_events')
            if not number_of_events: # Not present in the body as well, so we are assigning the default value
                number_of_events=100
                number_of_devices=5
            else:
                print(f"number_of_events:: {number_of_events}")
                number_of_devices = int(int(number_of_events)/20)
                print(f"number_of_devices:: {number_of_devices}")

    # This script simulates the production of events for 10 devices.
    devices = []
    for x in range(0, number_of_devices):
        devices.append(str(uuid.uuid4()))

    # Create a producer client to produce and publish events to the event hub.
    producer = EventHubProducerClient.from_connection_string(conn_str=CONNECTION_STR, eventhub_name=EVENTHUB_NAME)

    for y in range(0,20):    # For each device, produce 20 events. 
        event_data_batch = producer.create_batch() # Create a batch. You will add events to the batch later. 
        for dev in devices:
            # Create a dummy reading.
            reading = {'id': dev, 'timestamp': str(datetime.datetime.utcnow()), 'uv': random.random(), 'temperature': random.randint(70, 100), 'humidity': random.randint(70, 100)}
            s = json.dumps(reading) # Convert the reading into a JSON string.
            print(s)
            event_data_batch.add(EventData(s)) # Add event data to the batch.
        producer.send_batch(event_data_batch) # Send the batch of events to the event hub.

    # Close the producer.    
    producer.close()

    if (number_of_events):
        return func.HttpResponse(f"Total number of {number_of_events} events have been generated from {number_of_devices} devices. Each devices generated 20 events")
    else:
        return func.HttpResponse(
             "This EventGenerator function executed successfully. Provide number_of_events=<<value>> in the body or header to generate that number of events ",
             status_code=200
        )
