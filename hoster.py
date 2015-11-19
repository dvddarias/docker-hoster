#!/usr/bin/python3
from docker import Client
import argparse
import shutil
import signal
import time
import sys
import os

label_name = "hoster.domains"
enclosing_pattern = "#-----------Docker-Hoster-Domains----------\n"
hosts_path = "/tmp/hosts"
hosts = {}

def signal_handler(signal, frame):
    global hosts
    hosts = {}
    update_hosts_file()
    sys.exit(0)

def main():
    # register the exit signals
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    args = parse_args()
    global hosts_path
    hosts_path = args.file

    docker = Client(base_url='unix://%s'%args.socket)
    events = docker.events(decode=True)
    #get running containers
    for c in docker.containers(quiet=True,all=False):
        container_id = c["Id"]
        container = get_container_data(docker, container_id)
        hosts[container_id] = container

    update_hosts_file()

    #listen for events to keep the hosts file updated
    for e in events:
        status = e["status"];
        if status =="start":
            container_id = e["id"]
            container = get_container_data(docker, container_id)
            hosts[container_id] = container
            update_hosts_file()

        if status=="stop" or status=="die" or status=="destroy":
            container_id = e["id"]
            if container_id in hosts:
                hosts.pop(container_id)
                update_hosts_file()


def get_container_data(docker, container_id):
    #extract all the info with the docker api
    info = docker.inspect_container(container_id)
    container_ip = info["NetworkSettings"]["IPAddress"]
    container_name = info["Name"].strip("/")
    labels = info["Config"]["Labels"]
    domains = set()
    if label_name in labels:
        domains = domains.union([d.strip() for d in labels[label_name].split()])

    domains.add("%s.local"%container_name)

    return { "ip": container_ip, "name": container_name, "domains": domains}


def update_hosts_file():
    if len(hosts)==0:
        print("Removing all hosts before exit...")
    else:
        print("Updating hosts file with:")

    for k,v in hosts.items():
        print("ip: %s domains: %s"%(v["ip"],v["domains"]))

    #read all the lines of thge original file
    lines = []
    with open(hosts_path,"r+") as hosts_file:
        lines = hosts_file.readlines()

    #remove all the lines after the known pattern
    for i,line in enumerate(lines):
        if line==enclosing_pattern:
            lines = lines[:i]
            break;

    #remove all the trailing newlines on the line list
    while lines[-1].strip()=="": lines.pop()

    #append all the domain lines
    if len(hosts)>0:
        lines.append("\n\n"+enclosing_pattern)
        for k,v in hosts.items():
            lines.append("%s    %s\n"%(v["ip"],"   ".join(v["domains"])))
        lines.append("#-----Do-not-add-hosts-after-this-line-----\n\n")

    #write it on the auxiliar file
    aux_file_path = hosts_path+".aux"
    with open(aux_file_path,"w") as aux_hosts:
        aux_hosts.writelines(lines)

    #replace etc/hosts with aux file, making it atomic
    shutil.move(aux_file_path, hosts_path)


def parse_args():
    parser = argparse.ArgumentParser(description='Synchronize running docker container IPs with host /etc/hosts file.')
    parser.add_argument('socket', type=str, nargs="?", default="tmp/docker.sock", help='The docker socket to listen for docker events.')
    parser.add_argument('file', type=str, nargs="?", default="/tmp/hosts", help='The /etc/hosts file to sync the containers with.')
    return parser.parse_args()

if __name__ == '__main__':
    main()

