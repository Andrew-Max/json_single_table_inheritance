## What does it do

*Short Version:* A flexible single table inheritance(STI) framework that uses postgres JSON fields to avoid issues with column bloat and allow relational schemas and ActiveRecord without enforcing specific attributes for members of a table.

*Slightly Longer Version:*This gem allows you to design databases in rails which maintain relational consistency between categories of classes while allowing total flexibility of the attributes of those classes.

Say you have two rails Classes `Vehicle` and `Driver`. A `vehicle` always `has_and_belongs_to_many :drivers` and a `driver` always `has_and_belongs_to_many :vehicles` Yet you may have two kinds of vehicles for which the attributes on the objects look nothing alike. for example `class Airplane` may have attributes like `wing_span`, `cockpit_software_manufacturer`, and `landing_gear_type` that make no sense on `class Car`. JSON Single Table Inheritnace allows yout to store both of those classes on the same table without having to put those fields directly on the table which allows you to maintain the advantages of using a relational database and everything you get for free with ActiveRecord while keeping your distinct classes.

Storing multiple classes inherited from a common parent on a single table is commonly reffered to as STI or Single Table Inheritance. A common argument against single table inheritance is that the tables end up bloated because you would traditionally implement this by throwing all of those attributes on the parent class and then just using the ones you neeeded. So `Car` would have `wing_span: nil`. Becuase the JSON blobs don't have to be consistent between subtypes, you can avoid this problem and the tables only end up with two attrs: `type` and `json_data`.

## Installation


add to your gemfile:

`gem "json_single_table_inheritance"`



## Rails App Integration

The basic setup for this looks something like:

In your top level models directory, you will have the base class definitions which correspond to relational tables ie:


`app/models/vehicle.rb`

```ruby
class Vehicle < ApplicationRecord
  include JsonSingleTableInheritance # this adds all of the JSON STI functionality to the class

  has_and_belongs_to_many :vehicle_occupants

  has_and_belongs_to_many :other_non_sti_table

  belongs_to :some_second_sti_table
end
```

`app/models/vehicle_occupant.rb`

```ruby
class VehicleOccupant < ApplicationRecord
  has_and_belongs_to_many :vehicles
end
```

For each STI model you will then have a sub directory with a matching name which contains class definitions for it's subtypes and which use the `define_schema` helper to specify it's attributes:

`app/models/vehicle/airplane.rb`

```ruby
class Vehicle::Airplane < Vehicle
  define_schema({
    type: "object",
    properties: {
      wing_span: { type: "number" },
      tail_number: { type: "string" },
      has_propellers: { type: "boolean" },
    },
    required: []
  })
end
```

`app/models/vehicle/automobile.rb`

```ruby
class Vehicle::Automobile < Vehicle
  define_schema({
    type: "object",
    properties: {
      has_auto_transmission: { type: "boolean" },
      license_plate: { type: "string" },
      num_doors: { type: "integer" },
    },
    required: []
  })
end
```

The `JsonSingleTableInheritance` module then provides some utilities for dealing with these objects.

You can

- call the subtypes individually
  eg:  `Automobile.all` or `Airplane.create`

- you can call json attr getters and setters directly on objects like normal ActiveRecord attrs

  eg:  `plane = Airplane.new`
      
       `plane.tail_number = "N328KF"`
      
       `puts plane.tail_number`

- you can call relation finders on parent and subtypes

  eg:  `driver = VehicleOccupant.first`
        
        driver.vehicles # returns vehicles of all types`
        
       `driver.airplanes # returns only members of the vehicles table with type == Vehicle::Airplane`

- you can automatically seed your app for all of your JSON STI classes with                                          
       `JsonSingleTableInheritance::InheritableSeeder.seed!`
