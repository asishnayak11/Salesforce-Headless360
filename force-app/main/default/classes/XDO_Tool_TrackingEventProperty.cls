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
 * @date 12/1/2024
 *
 * TODO:
 */

public with sharing class XDO_Tool_TrackingEventProperty //NOPMD
{
    @AuraEnabled
    @InvocableVariable(Label='Name' Description='Property name to capture for the event. Snake case.' Required=true)
    public String name;

    @AuraEnabled
    @InvocableVariable(Label='Value' Description='Property value to capture for the event.' Required=true)
    public String value;

    /**
     * Constructors
     */
    public XDO_Tool_TrackingEventProperty() {
    }

    public XDO_Tool_TrackingEventProperty(String name, String value) {
        this.name = name;
        this.value = value;
    }
}