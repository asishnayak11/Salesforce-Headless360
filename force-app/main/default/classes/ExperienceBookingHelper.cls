public class ExperienceBookingHelper {
    public static void createExperienceSessions(String sessionId) {
        Session__c session = [
                SELECT Id, Capacity__c, Booked_Slots__c, Experience__c
                FROM Session__c
                WHERE Id = :sessionId
            ]
            .get(0);

        Integer capacity = Integer.valueOf(session.Capacity__c);
        Integer booked = Integer.valueOf(session.Booked_Slots__c);

        // Calculate the booking target as a random value between 80% and 95% of capacity.
        Double targetPercentage = 0.8 + (Math.random() * 0.15); // Random between 0.8 (80%) and 0.95 (95%)
        Integer targetCapacity = Integer.valueOf(
            Math.ceil(capacity * targetPercentage)
        );
        Integer slotsToFill = targetCapacity - booked;

        if (booked >= targetCapacity) {
            System.debug(
                'The Session is already within or above the target capacity range.'
            );
            return;
        }

        List<Contact> availableContacts = [
            SELECT Id
            FROM Contact
            WHERE
                Id NOT IN (
                    SELECT Contact__c
                    FROM Booking__c
                    WHERE Session__r.Experience__c = :session.Experience__c
                )
                AND Lifetime_Experience_Bookings__c <= 12
        ];

        List<Booking__c> newBookings = new List<Booking__c>();
        Integer contactIndex = 0;

        while (slotsToFill > 0 && contactIndex < availableContacts.size()) {
            Contact c = availableContacts.get(contactIndex);
            // Dynamically adjust the number of guests per booking based on remaining slots to fill and randomization
            Integer maxGuestsThisBooking = Math.min(6, slotsToFill);
            Integer numberOfGuests =
                Math.floor(Math.random() * maxGuestsThisBooking).intValue() + 1;

            Booking__c booking = new Booking__c(
                Contact__c = c.Id,
                Session__c = session.Id,
                Number_of_Guests__c = numberOfGuests
            );
            newBookings.add(booking);

            slotsToFill -= numberOfGuests;
            booked += numberOfGuests;
            contactIndex++;
        }

        if (!newBookings.isEmpty()) {
            try {
                insert newBookings;
                System.debug(
                    'Successfully created bookings for ' +
                        newBookings.size() +
                        ' contacts.'
                );
            } catch (DmlException e) {
                System.debug('Error creating new bookings: ' + e.getMessage());
            }
        }
    }
}