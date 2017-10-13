#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

from abc import ABC, abstractmethod

import kombu

import logging
import typing

from base_connect import _BaseConnect

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

# abstract base class for message broker services
class _MQ(_BaseConnect):

  # use localhost only credentials e.g. guest
  def __init__(self, protocol_, ip_, port_, username_, passwd_):
    super(_MQ, self).__init__()
    self._protocol = protocol_
    self._ip = ip_
    self._port = port_
    self._username = username_
    self._passwd = passwd_

  @abstractmethod
  def Publish(self, connection_, obj_):
    pass

  @abstractmethod
  def Consume(self, connection_):
    pass

# RabbitMQ
class RabbitMQ(_MQ):
  def __init__(self, username_, passwd_, exchange_, xtype_, routingKey_, protocol_ = 'amqp', ip_ = 'localhost', port_ = 5672):
    super(RabbitMQ, self).__init__(protocol_, ip_, port_, username_, passwd_)
    self._exchangeName = exchange_
    self._xtype = xtype_
    self._routingKey = routingKey_

    self._producer = None
    self._messages = []

  def _Connect(self):
    # lazy connector
    connection_ = kombu.Connection(self._protocol + "://" + self._username + ":" + self._passwd + "@" + self._ip + ":" + str(self._port) + "/")
    return connection_

  def _Close(self, connection_):
    # connection_.release()
    pass

  def Publish(self, connection_, obj_):
    if self._producer == None:
      channel_ = connection_.channel()
      exchange_ = kombu.Exchange(self._exchangeName, type = self._xtype)
      self._producer = kombu.Producer(exchange = exchange_, channel = channel_, routing_key = self._routingKey)
    self._producer.publish(obj_)

  def GetMessages(self):
    return self._messages

  def GetMessage(self, index_):
    return self.GetMessages()[index_]

  def AcknowledgeMessage(self, index_):
    self.GetMessage(index_).GetSecond().ack()
    del self.GetMessages()[index_]

  def ReceiveNewMessage(self, payload_, message_):
    self.GetMessages().append(Pair(payload_, message_))

  def Consume(self, connection_, queueName_, consumerArgs = {}, callbacks = [ ReceiveNewMessage ], timeOut = 5):
    channel_ = connection_.channel()
    exchange_ = kombu.Exchange(self._exchangeName, type = self._xtype)
    queue_ = kombu.Queue(queueName_, exchange_, self._routingKey, consumer_arguments = consumerArgs)
    with kombu.Consumer(connection_, queue_, callbacks) as self._consumer:
      connection_.drain_events(timeOut)
