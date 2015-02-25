# Abstract #

Star Made uses a file based log system, a non very comfortable way for server admins to control what is happening, specially to moderate some player behaviours. The idea of this project is to provide a better way to monitor the server status and to review logs.

To achieve this we will use the combination of three software solutions: Logstash, ElasticSearch and Kibana.

Logstash will read, pre-process and then store the log lines into ElasticSearch. Then, with Kibana we'll read the data from ElasticSearch and we'll be able to create several Dashboard to visualize the data. For example, we'll make a "Chat Dashboard" where we will be able to read and filter the players conversations, ideal to resolve disputes between players.

# Logstash #

"Logstash is a tool for managing events and logs. You can use it to collect logs, parse them, and store them for later use (like, for searching). Speaking of searching, logstash comes with a web interface for searching and drilling into all of your logs."

 - Prerequisites: Java
 - Official Site: http://logstash.net/

## Installing ##

For my environment (CentOS) I have installed it as a service with yum:

<code>wget https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.2-1_2c0f5a1.noarch.rpm
yum install logstash-1.4.2-1_2c0f5a1.noarch.rpm </code>

## Configuring ##

Once installed, you will find the configuration folder in /etc/logstash/conf.d/. We will create there a file that will start monitoring the log.txt.0 file from the logs file of the StarMade installation. Copy and edit the /logstash/config/starmade.conf from the project files.

Logstash needs an Input and an Output. In the configuration file you will find that we will be using a file type input and you will need to set the path property to your server's log.txt.0 file.

### Multiline codec ###

The default file input will assume that every line break defines the end of a log entry. This is generally true for Star Made, but some times not. For example, if you try to execute a non existant command, a Java exception will rise and those uses several lines to print the stack trace.

To handle this we have set a multiline codec. This option will allow us to group log lines with a criteria. All StarMade log entries starts with a timestamp, then, we will assume that every line **not** starting with the timestamp pattern will be part of the previous entry.