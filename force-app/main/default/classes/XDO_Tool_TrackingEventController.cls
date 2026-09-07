/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */


/**
 * @author Paul Lucas
 * @company       Salesforce
 *
 * @date 29/11/2023
 *
 * TODO:
 */

public with sharing class XDO_Tool_TrackingEventController //NOPMD
{
    @AuraEnabled
    public static String getSiteId() {
        return Site.getSiteId();
    }

    @AuraEnabled
    public static void publishTrackingEvent(String serializedEvent) {
        Map<String, Object> event = (Map<String, Object>) JSON.deserializeUntyped(serializedEvent);

        System.debug('>>>>> XDO_Tool_TrackingEventController.publishTrackingEvent.event: ');
        System.debug(event);

        EventBus.publish(new XDO_Tool_Platform_Tracking_Event__e(
                Action__c = String.valueOf(event.get('action')),
                Asset_Identifier__c = String.valueOf(event.get('asset_identifier')),
                Event__c = String.valueOf(event.get('event')),
                Once__c = Boolean.valueOf(event.get('once')),
                Payload__c = serializedEvent,
                Type__c = String.valueOf(event.get('type')),
                User_Id__c = UserInfo.getUserId() // TODO: Test if user context is retained from Experience Cloud

//                User_Id__c = String.valueOf(event.get('userId'))

//                Page__c = String.valueOf(event.get('page')),
//                Value__c = String.valueOf(event.get('value'))
        ));
    }
}