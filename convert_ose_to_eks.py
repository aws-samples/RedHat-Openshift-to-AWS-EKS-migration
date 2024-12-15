import os
import yaml
from yaml import Dumper
from pathlib import Path
import shutil


def convert_openshift_to_helm(openshift_deployment_file):
    with open(openshift_deployment_file, 'r') as f:
       # openshift_data = yaml().load_all(f)
        openshift_data = yaml.safe_load_all(f)

        helm_values_all = {}
        for data in openshift_data:
            if 'spec' in data and 'template' in data['spec'] and 'spec' in data['spec']['template']:
                container = data['spec']['template']['spec']['containers'][0]
                app_name = container['name']
                image = container['image']
                
                app_ports = [{'containerPort': port['containerPort'], 'protocol': port.get('protocol', 'TCP')}
                             for port in container['ports']]
                resources = container['resources']
                replicas = data['spec']['replicas']
                liveness_probe = container.get('livenessProbe', {})
                readiness_probe = container.get('readinessProbe', {})
                env_variables = container.get('env', [])
                app_env = [{'name': env.get('name', ''), 'value': env.get('value', '')} for env in env_variables]

                ingress_host = ""
                gtm_ingress_host = ""

                if 'items' in data['spec']:
                    for item in data['spec']['items']:
                        if 'kind' in item and item['kind'] == 'Route':
                            host = item['spec'].get('host', '')
                            if host:
                                ingress_host = host
                                gtm_ingress_host = host

                helm_values = {
                    'appname': app_name,
                    'appImage': {
                        'image': image,
                        'tag': image.split(':')[-1]
                    },
                    'appEnv': app_env,
                    'appContainerPorts': app_ports,
                    'appResources': {
                        'limits': resources.get('limits', {}),
                        'requests': resources.get('requests', {})
                    },
                    'appLivenessProbe': liveness_probe,
                    'appReadinessProbe': readiness_probe,
                    'autoscaling': {'enabled': False},
                    'replicaCount': replicas,
                    'ingress': {
                        'enabled': True,
                        'hostname': ingress_host,
                        'port': app_ports[0]['containerPort']
                    },
                    'gtmIngress': {
                        'enabled': True,
                        'hostname': gtm_ingress_host,
                        'port': app_ports[0]['containerPort']
                    }
                }
                helm_values_all["app"] = helm_values
                

        return helm_values_all

def write_helm_values(helm_values_all, output_file):
    try:
        # Check if the output file exists
        if os.path.isfile(output_file):
            # If the file exists, delete it
            os.remove(output_file)
         # Open the file in write mode to create a new file or overwrite the existing one
        with open(output_file, 'w') as f:
            #yaml().dump(helm_values_all, f)
            yaml.dump(helm_values_all, f, Dumper=Dumper)
    except IOError as e:
        print(f"Error writing  values to file: {e}")

def convert_all_openshift_to_helm(input_folder, output_folder,template_folder_path):
    if not os.path.exists(input_folder):
        print(f"Input folder '{input_folder}' does not exist.")
        exit(1)

    for filename in os.listdir(input_folder):
        if filename.endswith(".yaml"):
            
            openshift_deployment_file = os.path.join(input_folder, filename)
            
            helm_values = convert_openshift_to_helm(openshift_deployment_file)
            
            os.makedirs(output_folder, exist_ok=True)

            app_name = Path(filename).stem
            app_folder = os.path.join(output_folder, app_name)
            os.makedirs(app_folder, exist_ok=True)
            output_file = os.path.join(app_folder, "values.yaml")
            
            write_helm_values(helm_values, output_file)
            chart_yaml_content = f"""apiVersion: v2
name: {app_name}
description: A Helm chart for Kubernetes for application {app_name}
type: application
version: 0.1.0
appVersion: "1.0.0"
"""
            chart_yaml_file = os.path.join(app_folder, "Chart.yaml")
            try:
                if os.path.isfile(chart_yaml_file):
                    # If the file exists, delete it    
                    os.remove(chart_yaml_file)
                with open(chart_yaml_file, "w") as f:
                    f.write(chart_yaml_content)
            except IOError as e:
                print(f"Error writing  values to file: {e}")
            # Copy templates from template_folder to app_folder
            template_source = os.path.join(template_folder_path, "templates")
            template_dest = os.path.join(app_folder, "templates")
            try:
                os.makedirs(template_dest, exist_ok=True)
                src_dir = Path(template_source)
                dest_dir = Path(template_dest)
                for item in src_dir.iterdir():
                    if item.is_file():
                        src_path = item
                        dest_path = dest_dir / item.name
                        
                        # Remove the destination file if it already exists
                        if dest_path.exists():
                            dest_path.unlink()
                        
                        shutil.copy2(src_path, dest_path)
                        #print(f"Copied {src_path} to {dest_path}")    

            except shutil.Error as e:
                print(f"Error copying templates: {e}")
            except OSError as e:
                print(f"Error creating or removing destination directory: {e}")

    print("Conversion completed successfully.")

if __name__ == '__main__':
    input_folder = 'SRC_REPO'
    output_folder = 'DEST_REPO'
    template_folder_path= 'Operation'

    convert_all_openshift_to_helm(input_folder, output_folder,template_folder_path)