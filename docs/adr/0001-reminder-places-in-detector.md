# Reminder Places are detected by the Detector, not Android geofencing

Reminder Places use the same location readings as Stays, inside the pure Detector. Android geofencing might use less battery, but it depends on Play services, can be late, and can't be tested with recorded movement, which the project rules require. The cost is that a Reminder can come later while readings are slowed during a Stay; FT-6 checks this.
