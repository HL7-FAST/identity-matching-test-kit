require "uri"
require "json"
require "net/http"
require 'webmock/rspec'
require 'logger'

module InfernoTemplate
 
  class PatientGroup < Inferno::TestGroup
    title 'Patient  Tests'
    description 'Verify that the server makes Patient resources available'
    id :patient_group

        
    test do
      title 'Patient match is valid'
      description %(
        Verify that the Patient  $match resource returned from the server is a valid FHIR resource.
      )
      
      input :search_json ,
        type: 'textarea'
      
      output :response_json
      # Named requests can be used by other tests
      makes_request :match
      
      

      logger= Logger.new(STDOUT)
      # create a named client for a group
      fhir_client  do
        url :url
      end
 
      run do
        body = JSON[search_json] 
        body ={
          "resourceType": "Parameters",
          "id": "example",
          "parameter": [
            {
              "name": "resource",
              "resource": {
                "resourceType": "Patient",
                "id": "1244780",
                "identifier": [
                  {
                    "type": {
                      "coding": [
                        {
                          "system": "http://terminology.hl7.org/CodeSystem/v2-0203",
                          "code": "DL",
                          "display": "Drivers License"
                        }
                      ],
                      "text": "Drivers License"
                    },
                    "value": "Q147604567"
                  }
                ],
                "name": [
                  {
                    "family": "Queentin",
                    "given": [
                      "Vladimir"
                    ]
                  }
                ],
                "maritalStatus": {
                  "coding": [
                    {
                      "system": "http://terminology.hl7.org/CodeSystem/v3-MaritalStatus",
                      "code": "M"
                    }
                  ]
                },
                "telecom": [
                  {
                    "system": "phone",
                    "value": "344-845-5689",
                    "use": "mobile"
                  }
                ],
                "address": [
                  {
                    "type": "physical",
                    "line": [
                      "321 South Maple Street"
                    ],
                    "city": "Scranton",
                    "state": "PA",
                    "postalCode": "18503",
                    "use": "home"
                  }
                ],
                "gender": "male",
                "birthDate": "1956-12-01"
              }
            },
            {
              "name": "count",
              "valueInteger": "3"
            },
            {
              "name": "onlyCertainMatches",
              "valueBoolean": "false"
            }
          ]
        }
        
          #puts("request url=" +  url)
          #puts("request body= #{body}" )
          fhir_operation("Patient/$match", body: body, client: :default, name: nil, headers: { 'Content-Type': 'application/fhir+json' })

          #puts("response body=" +  response[:body])
          #fhir_operation("Patient/$match", body: body, client: :default, name: nil, headers: { 'Content-Type': 'application/fhir+json' })

          
          #response_json=response[:body]
          output response_json: response[:body]
          #output response_json: response_json
          assert_response_status(200)
          #assert_resource_type(:bundle)
             
      end
    end
    test do
      input :expectedResultCnt
      input :response_json
      output :numberOfRecordsReturned
      title 'Patient match - determines whether or not the $match function returns every valid record'
      description %(Match output SHOULD contain every record of every candidate identity, subject to volume limits
      )
      run do
        
          #puts response_json  
          response = JSON[response_json]
          assert_valid_json(response_json, message = "Invalid JSON response received - expected: #{expectedResultCnt} - received: #{numberOfRecordsReturned}")
          numberOfRecordsReturned = response['total'] 
          puts "number of records returned in bundle ---- #{numberOfRecordsReturned} " 
          puts "number of records expected in bundle ---- #{expectedResultCnt} " 
          assert numberOfRecordsReturned.to_s() == expectedResultCnt.to_s(), "Incorrect Number of Records returned"
          
          output numberOfRecordsReturned: numberOfRecordsReturned
            
         
      end
      run do
        
        #puts response_json  
        response = JSON[response_json]
        assert_valid_json(response_json, message = "Invalid JSON response received - expected: #{expectedResultCnt} - received: #{numberOfRecordsReturned}")
        numberOfRecordsReturned = response['total'] 
        puts "number of records returned in bundle ---- #{numberOfRecordsReturned} " 
        puts "number of records expected in bundle ---- #{expectedResultCnt} " 
        assert numberOfRecordsReturned.to_s() == expectedResultCnt.to_s(), "Incorrect Number of Records returned"
        
        output numberOfRecordsReturned: numberOfRecordsReturned
          
       
    end
    end
  end
end
