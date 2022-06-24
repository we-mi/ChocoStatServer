# ChocoStatServer - REST-API documentation

## Notes

Every api call mentioned in this document is prefixed with `/api/v1/`.

A complete api call url will look like this (assuming the default parameters):

`https://server:2306/api/v1/computers`

Every parameter (except usernames, passwords, tokens and so on) can be passed as a HTTP-GET or HTTP-POST parameter. The beforementioned exceptions can only be passed as HTTP-POST parameters.  
If a parameter was passed as a HTTP-GET *and* HTTP-POST parameter, the HTTP-POST parameter has precedence.

The example calls in this document won't use HTTPS for simplicity. You should however always use HTTPS unless you know what you're doing.

For most of the functions you will need a *Token*.
You need to login through the endpoint `POST /api/v1/auth/login` and provide a username and a password as POST-Parameters. If the login succeeds the token is send as an answer in Json-Format.

There is no real user database right now, but an LDAP-Auth-Backend is definitly planned.
It is up to you to search for the current login data.

The mentioned examples can all be executed after the database has been filled with the demo data from `demo-db-module.ps1` from the root of this project.

## Methods

|HTTP-Method|Explanation|
|-----------|-----------|
|GET|Retrieve data|
|POST|Create new data or replace a dataset|
|PUT|Update data or add new data to a dataset|
|DELETE|Remove data|

## Endpoints

### Computers

#### List available computers

Get a list of available computers, sorted by computername alphabetically

`GET /api/v1/computers/`

##### Parameters

|Parameter|Type|Explanation|Mandatory|Example|
|---------|----|-----------|------|-------|
|ID|Integer|Filter for specific computer IDs. Might contain wildcards|No|1027|
|Name|String|Filter for specific computer names. Might contain wildcards|No|*.example.org|
|Before|Datetime|Only list computers with a `lastContact`-Date before this date|No|2022-01-01 00:00:00|
|After|Datetime|Only list computers with a `lastContact`-Date after this date|No|2021-01-01 00:00:00|
|Limit|Integer|Limit the output to this amount of results|No|100|

##### Example request

``` powershell
$params = @{
    Name = "*.example.org"
    After = "2022-01-01 00:00:00"
} | ConvertTo-Json

Invoke-RestMethod -Method "GET" -Uri 'http://server:2306/api/v1/computers' -Body $params
```

##### Example output

``` json
[
  {
    "ComputerID": 2,
    "ComputerName": "bar.example.org",
    "LastContact": "2022-06-24T20:13:12"
  },
  {
    "ComputerID": 1,
    "ComputerName": "foo.example.org",
    "LastContact": "2022-06-24T20:13:12"
  }
]
```
