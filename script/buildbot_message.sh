#!/bin/bash

script/runner -e production "Message.create(:participant => Participant.find_by_username('autobuilder'), :chat_room => ChatRoom.find_by_name('Builds'), :content => '$1')"
