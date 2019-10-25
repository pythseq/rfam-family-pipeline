#!/usr/bin/env python

import os
import sys
import argparse
import subprocess
import getpass
import socket

from subprocess import Popen, PIPE
#from kubernetes import client, config, utils

# --------------------------------------------------------------------------------------------


def create_new_user_login_pod(username):
	"""
	This function creates a new user login pod using a kubernetes deployment manifest.
	The purpose of the login pods is to provision the users with interactive sessions
	and access to the rfam curation pipeline on the Cloud.

	username: A valid Rfam cloud account username

	return: void	
	"""

	config.load_incluster_config()
    	k8s_client = client.ApiClient()

	k8s_deployment_str = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rfam-login-pod-USERID
  labels:
    app: rfam-family-builder-USERID
    tier: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rfam-family-builder-USERID
  template:
    metadata:
      name: rfam-login-pod-USERID
      labels:
        app: rfam-family-builder-USERID
        user: USERID
        tier: frontend  
    spec:
      containers:
      - name: rfam-login-pod-USERID
        image: ikalvari/rfam-cloud:kubes
        imagePullPolicy: Always
        ports:
        - containerPort: 9876
        volumeMounts:
        - name: rfam-login-pod-storage-USERID # this one must match the volume name of the pvc
          mountPath: /workdir
        - name: nfs-pv
          mountPath: /Rfam/rfamseq
        stdin: true
        tty: true
      volumes:
      - name: rfam-login-pod-storage-USERID
        persistentVolumeClaim:
          claimName: rfam-pvc-USERID # this one must match the pvc name
      - name: nfs-pv
        persistentVolumeClaim:
          claimName: nfs-pvc
      restartPolicy: Always"""

	k8s_deployment_str = k8s_deployment_str.replace("USERID", username)

	login_deployment = os.path.join("/tmp", "rfam_k8s_login.yaml")
	
	fp = open(login_deployment, 'w')
	fp.write(login_deployment % username)
	fp.close()

	k8s_api = utils.create_from_yaml(k8s_client, login_deployment)

# --------------------------------------------------------------------------------------------

def check_k8s_login_deployment_exists(username):

	"""
	Uses kubectl to check if a login pod for a specific user exists.
	Returns True if the login pod exists, False otherwise

	username: A valid Rfam cloud account username

	return: Boolean
	"""
	
	k8s_cmd_args = ["kubectl", "get", "pods", "--selector=user=%s,tier=frontend" % username]	
	process = Popen(k8s_cmd_args, stdin=PIPE, stdout=PIPE, stderr=PIPE)
        output, err = process.communicate()

        login_pod = output.strip().split('\n')[1:]

	if len(login_pod) == 0:
		return False
	
	return True

# --------------------------------------------------------------------------------------------

def get_k8s_login_pod_id(username):

        """
        This function uses kubectl command to fetch the login pod_id of a specific user of
	the Rfam cloud infrastructure. It returns the the user's login pod_id, otherwise it
	returns None. 

        username: A valid Rfam cloud account username

        return: The user login pod_id if it exists, None otherwise 
        """

        k8s_cmd_args = ["kubectl", "get", "pods", "--selector=user=%s,tier=frontend" % username]
        process = Popen(k8s_cmd_args, stdin=PIPE, stdout=PIPE, stderr=PIPE)
        output, err = process.communicate()

        login_pod_line = output.strip().split('\n')[1:]

	if len(login_pod_line)!=0:	
		login_pod_id = [x for x in login_pod_line[0].split(' ') if x!=''][0]
       		
		return login_pod_id
	
	return None

# --------------------------------------------------------------------------------------------

def get_interactive_rfam_cloud_session(username):
	"""
	This function allows a user to login to their interactive login pod and get access to
	the Rfam cloud curation pipeline. If the login pod does not exist, a new one will be
	created and the function waits until the pod is in running state.

	username: A valid Rfam cloud account username

	return: void 
	"""
	
	# variable declarations
	user_login_pod_id = ""
	exec_cmd = "kubectl exec -it %s bash"
	
	# check if the user login pod exists
	login_exists = check_k8s_login_deployment_exists(username)
	
	if login_exists:
		user_login_pod_id = get_k8s_login_pod_id(username)

	else:
		# create a new user login pod
		create_new_user_login_pod(username)
		
		# wait while login pod is being created
		while (not login_exists):
			login_exists = check_k8s_login_deployment_exists(username)

		# if it reaches this point it means the login pod was created
		# and we can login to it
		user_login_pod_id = get_k8s_login_pod_id(username)
	
	subprocess.call(exec_cmd % user_login_pod_id, shell=True)

# --------------------------------------------------------------------------------------------

def get_username():
	"""
	Function to detect and return the username of an Rfam cloud user.

	return: An Rfam cloud user's username 
	"""
	
	username = ""
	hostname = socket.gethostname()
	
	# check host name to decide if on edge node or in pod 
	if hostname.find("master") != -1 or hostname.find("edge") != -1:
		username = getpass.getuser()
	
	# check if in pod
	elif hostname.find("login") != -1:
		username = hostname.split('-')[3]

	else:
		sys.exit("Username could not be detected. Unknown location.\n")

	return username
		

# --------------------------------------------------------------------------------------------

def parse_arguments():
	"""
	Uses python's argparse to parse the command line arguments
	
	return: Argparse parser object
	"""

	# create a new argument parser object
    	parser = argparse.ArgumentParser(description='')

    	parser.add_argument('--start', help='start a new interactive curation session', 
				action="store_true")

	return parser

# --------------------------------------------------------------------------------------------

if __name__=="__main__":

	# create a new argument parser object
	parser = parse_arguments()
	args = parser.parse_args()

	if args.start:
		username = get_username()
		get_interactive_rfam_cloud_session(username)
	
