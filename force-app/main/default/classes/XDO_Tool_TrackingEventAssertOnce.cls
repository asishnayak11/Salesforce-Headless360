/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */


/**
     @author        Paul Lucas
     @company       Salesforce
     @description   
     @date          13/4/2024

     TODO: Filter out staged events that have not been set to "Once" but where an incoming event subsequently has.
            Not trivial as you need to check the stage of each staged event to avoid corruption
 */

public with sharing class XDO_Tool_TrackingEventAssertOnce extends XDO_Tool_TrackingEventProcessor //NOPMD
{
    public XDO_Tool_TrackingEventAssertOnce() {
        this(null);
    }

    public XDO_Tool_TrackingEventAssertOnce(XDO_Tool_TrackingEventProcessor next) {
        super(next);
    }

    public override void process(List<XDO_Tool_Platform_Tracking_Event__e> trackingEvents) {
        Boolean isDuplicate = false;
        Integer items = trackingEvents.size() - 1;
        Set<String> eventContexts = new Set<String>();

        List<XDO_Tool_Tracking_Event__c> stagedEvents = [
                SELECT Action__c,
                        Asset_Identifier__c
                FROM XDO_Tool_Tracking_Event__c
                WHERE Once__c = TRUE
        ];

        for (Integer i = items; i >= 0; i--) {
            for (XDO_Tool_Tracking_Event__c stagedEvent : stagedEvents) {
                if (trackingEvents[i].Action__c == stagedEvent.Action__c) {
                    isDuplicate = true;
                    break;
                }
            }

            if (isDuplicate || eventContexts.contains(trackingEvents[i].Action__c)) {
                trackingEvents.remove(i);
            } else {
                eventContexts.add(trackingEvents[i].Action__c);
            }

            isDuplicate = false;
        }

        super.process(trackingEvents);
    }
}