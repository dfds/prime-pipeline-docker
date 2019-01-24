import boto3
import coto
from boto.sts import STSConnection
import sys
import json

def load_json(path):
    with open(path) as json_data:
        d = json.load(json_data)
        return d

def update_tax_registration(role_arn, json_data):
    """
    Sets Legal and Tax settings on the first available TaxRegistration on an AWS account

    Usage:
        pipenv run python taxregistrations.py <ARN_OF_ROLE_TO_ASSUME> <PathToTaxSettingsJsonDocument>

    Example:
        pipenv run python taxregistrations.py "arn:aws:iam::999999999999:role/role-with-billing-permissions" "taxsettings.json"
    """
    
    sts_connection = STSConnection()
    assumed_role_object = sts_connection.assume_role(
        role_arn=role_arn,
        role_session_name="AssumeRoleSession")

    session = coto.Session(
        boto3_session = boto3.Session(
            aws_access_key_id=assumed_role_object.credentials.access_key,
            aws_secret_access_key=assumed_role_object.credentials.secret_key,
            aws_session_token=assumed_role_object.credentials.session_token))


    billing = session.client("billing")
    taxRegistrations = billing.list_tax_registrations()

    if len(taxRegistrations) < 1:
        print("No TaxRegistrations are present.")
        return
    
    taxRegistrations[0]['registrationId'] = json_data['registrationId']
    taxRegistrations[0]['legalName'] = json_data['legalName']
    taxRegistrations[0]['address']['addressLine1'] = json_data['addressLine1']
    taxRegistrations[0]['address']['addressLine2'] = json_data['addressLine2']
    taxRegistrations[0]['address']['city'] = json_data['city']
    taxRegistrations[0]['address']['countryCode'] = json_data['countryCode']
    taxRegistrations[0]['address']['postalCode'] = json_data['postalCode']
    taxRegistrations[0]['address']['state'] = json_data['state']
    
    billing.set_tax_registration(
        TaxRegistration = taxRegistrations[0]
    )



if __name__ == "__main__":
    if not len(sys.argv)==3:
        print("Please provide exactly 2 parameters. RoleARN and Path to json-payload")
        exit(1)
    json_data = load_json(sys.argv[2])
    update_tax_registration(sys.argv[1], json_data )