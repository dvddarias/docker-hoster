#!/usr/bin/python3
import docker
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
networks = []
masks = []

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
    global networks
    networks = args.networks
    global masks
    masks = args.masks

    dockerClient = docker.APIClient(base_url='unix://%s' % args.socket)
    events = dockerClient.events(decode=True)
    #get running containers
    for c in dockerClient.containers(quiet=True, all=False):
        container_id = c["Id"]
        container = get_container_data(dockerClient, container_id)
        hosts[container_id] = container

    update_hosts_file()

    #listen for events to keep the hosts file updated
    for e in events:
        if e["Type"]!="container": 
            continue
        
        status = e["status"]
        if status =="start":
            container_id = e["id"]
            container = get_container_data(dockerClient, container_id)
            hosts[container_id] = container
            update_hosts_file()

        if status=="stop" or status=="die" or status=="destroy":
            container_id = e["id"]
            if container_id in hosts:
                hosts.pop(container_id)
                update_hosts_file()

def add_domains_with_filtering(result, ip, name, domains):
    if masks:
        filtered_domains = []
        for domain in domains:
            for mask in masks:
                if mask in domain:
                     filtered_domains.append(domain)
                     break
        domains = filtered_domains
    if domains:
        result.append({
            "ip": ip,
            "name": name,
            "domains": domains
        })

def get_container_data(dockerClient, container_id):
    #extract all the info with the docker api
    info = dockerClient.inspect_container(container_id)
    container_hostname = info["Config"]["Hostname"]
    container_name = info["Name"].strip("/")
    container_ip = info["NetworkSettings"]["IPAddress"]

    result = []

    if networks:
        for network in networks:
            if network in info["NetworkSettings"]["Networks"]:
                network_data = info["NetworkSettings"]["Networks"][network]
                add_domains_with_filtering(
                    result,
                    network_data["IPAddress"],
                    container_name,
                    network_data["Aliases"]
                )
    else:
        for values in info["NetworkSettings"]["Networks"].values():
            if not values["Aliases"]:
                continue

            add_domains_with_filtering(
                result,
                values["IPAddress"],
                container_name,
                set(values["Aliases"] + [container_name, container_hostname])
            )

        if container_ip:
            add_domains_with_filtering(
                result,
                container_name,
                container_name,
                [container_name, container_hostname ]
            )

    return result


def update_hosts_file():
    if len(hosts)==0:
        print("Removing all hosts before exit...")
    else:
        print("Updating hosts file with:")

    for id,addresses in hosts.items():
        for addr in addresses:
            print("ip: %s domains: %s" % (addr["ip"], addr["domains"]))

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
        
        for id, addresses in hosts.items():
            for addr in addresses:
                lines.append("%s    %s\n"%(addr["ip"],"   ".join(addr["domains"])))
        
        lines.append("#-----Do-not-add-hosts-after-this-line-----\n\n")

    #write it on the auxiliar file
    aux_file_path = hosts_path+".aux"
    with open(aux_file_path,"w") as aux_hosts:
        aux_hosts.writelines(lines)

    #replace etc/hosts with aux file, making it atomic
    shutil.move(aux_file_path, hosts_path)


def parse_args():
    parser = argparse.ArgumentParser(description='Synchronize running docker container IPs with host /etc/hosts file.')
    parser.add_argument('socket', type=str, nargs="?", default="/tmp/docker.sock", help='The docker socket to listen for docker events.')
    parser.add_argument('file', type=str, nargs="?", default="/tmp/hosts", help='The /etc/hosts file to sync the containers with.')
    parser.add_argument('--networks', type=str, nargs="*", default=None, help='Manage aliases only for this docker network name.')
    parser.add_argument('--masks', type=str, nargs="*", default=None, help='Mask for filtering aliases')
    return parser.parse_args()

if __name__ == '__main__':
    main()

