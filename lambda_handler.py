import boto3,time
 


ec2 = boto3.client('ec2', region_name='us-east-1')
TAG = "Blog-WP-Blog.elliottlamararnold.com"

def get_wp_instance_id():
    res = ec2.describe_instances().get('Reservations')
    return [i.get('Instances')[0]['InstanceId'] for i in res if i.get('Instances')[0]['Tags'][0]['Value'] == TAG ][0]

def create_image():
    kwargs = {"InstanceId":get_wp_instance_id(), "Name": f"{TAG}-{time.time.time()}"}
    return  ec2.create_image(**kwargs)


def lambda_handler(event,context):
    create_image()


