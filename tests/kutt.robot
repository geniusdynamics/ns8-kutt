*** Settings ***
Library    SSHLibrary

*** Variables ***
${TEST_HOST}    kutt.ns8-ci.test

*** Test Cases ***
Check if kutt is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if kutt can be configured
    ${rc} =    Execute Command
    ...    api-cli run module/${module_id}/configure-module --data '{"host":"${TEST_HOST}","http2https":false,"lets_encrypt":false,"site_name":"CI Kutt","link_length":7,"disallow_anonymous_links":true}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if kutt configuration reads back
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration --data '{}'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    ${config} =    Evaluate    json.loads('''${output}''')    modules=json
    Should Be Equal    ${config}[host]    ${TEST_HOST}
    Should Be Equal    ${config}[site_name]    CI Kutt
    Should Be Equal As Integers    ${config}[link_length]    7
    Should Be Equal    ${config}[oidc_client_secret_set]    ${False}

Check if OIDC without a client secret is refused
    ${rc} =    Execute Command
    ...    api-cli run module/${module_id}/configure-module --data '{"host":"${TEST_HOST}","oidc_enabled":true,"oidc_issuer":"https://sso.ns8-ci.test","oidc_client_id":"kutt"}'
    ...    return_rc=True  return_stdout=False
    Should Not Be Equal As Integers    ${rc}  0

Check if kutt works as expected
    # The first start runs the database migrations: give Kutt a few minutes.
    # A new instance answers with the page that creates the admin account.
    ${rc} =    Execute Command    bash -c 'for i in $(seq 1 60); do curl -s -o /dev/null -f --resolve ${TEST_HOST}:80:127.0.0.1 http://${TEST_HOST}/ && exit 0; sleep 5; done; exit 1'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    ${output}  ${rc} =    Execute Command    curl -s -L --resolve ${TEST_HOST}:80:127.0.0.1 http://${TEST_HOST}/
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Contain    ${output}    CI Kutt

Check if the secrets stay out of the environment
    ${output}  ${rc} =    Execute Command    runagent -m ${module_id} bash -c 'grep -cE "PASSWORD|SECRET" environment; stat -c %a passwords.env postgres.env kutt.env'
    ...    return_rc=True
    Should Be Equal As Strings    ${output}    0\n600\n600\n600

Check if kutt is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
