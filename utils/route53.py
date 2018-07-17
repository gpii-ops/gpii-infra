#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
route53.py:

Retrieves the A, CNAME and TXT records of a Route53 DNS zone in Terraform format.

Instructions:

    - mkvirtualenv aws
    - pip install boto3
    - Set the credentials at ~/.aws/credentials
    - python route53.py > /tmp/dns-records.tf

The Route53 zone is hardcoded in the default value of the HostedZoneId variable.

"""

__author__      = "Raising the Floor US"
__copyright__   = "https://github.com/GPII/universal/blob/master/LICENSE.txt"


import boto3
import operator
from botocore.exceptions import ClientError

def printRecords(RecordType='A'):
    print("### " + RecordType + " ###\n\n")
    client = boto3.client('route53')
    paginator = client.get_paginator('list_resource_record_sets')
    try:
        source_zone_records = paginator.paginate(HostedZoneId='Z26C1YEN96KOGI')
        for record_set in source_zone_records:
            record_set['ResourceRecordSets'].sort(key=operator.itemgetter('Name'))
            for record in record_set['ResourceRecordSets']:
                if record['Type'] == RecordType:
                    print ('resource "google_dns_record_set" "%s-%s" {' % (RecordType.lower(),record['Name'][:-1].replace('-','--').replace('.','-')))
                    print ('  managed_zone = "${module.gcp_zone.gcp_name}"')
                    print ('  name    = "%s"' % (record['Name']))
                    print ('  type    = "%s"' % (RecordType))
                    print ('  ttl     = "%s"' % (str(record['TTL'])))
                    print ('  rrdatas = [')
                    print (',\n'.join(['    "%s"' % (value['Value'].replace("\"","\\\"")) for value in record['ResourceRecords']]))
                    print ('  ]')
                    print ('}\n')
    except Exception as error:
        print ('An error occured getting source zone records')
        print(error)
        exit(1)


if __name__ == "__main__":
    [ printRecords(RecordType) for RecordType in ['A','CNAME','TXT']]
