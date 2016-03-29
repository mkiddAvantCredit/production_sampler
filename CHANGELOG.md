## Version 0.5.1
* Zach Taylor pointed out an issue with table names. PR #4
    - Some test suites define anonymous classes which inherit from ActiveRecord::Base. This ensures those classes name 
    method, which responds as nil, are removed before sorting is attempted. Without this, an error is raised due to 
    comparing some string with nil.

## Version 0.5.0
* Add support for different primary key on the parent table in a one-to-many relationship/

## Version 0.4.1
* Internal refactor that better organizes the file structure. No change in functionality.

## Version 0.4.0
* Added #build_sql feature for generating the SQL statements for importing data from production into a development db.

## Version 0.3.0
* Add support for "where" conditions in the model spec. See production_sampler_spec.rb for implementation details.
