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
 * @date 6/2/2024
 *
 * TODO:
 */

public without sharing abstract class XDO_Tool_TrackingEventProcessor //NOPMD
{
    private XDO_Tool_TrackingEventProcessor next;

    public XDO_Tool_TrackingEventProcessor(XDO_Tool_TrackingEventProcessor next) {
        this.next = next;
    }

    public virtual void process(List<XDO_Tool_Platform_Tracking_Event__e> trackingEvents) {
        if (!trackingEvents.isEmpty()) {
            next?.process(trackingEvents);
        }
    }

    public static XDO_Tool_TrackingEventProcessor getProcessors() {
        return new XDO_Tool_TrackingEventRemoveEdits(
                new XDO_Tool_TrackingEventFinalizer());

        // return new XDO_Tool_TrackingEventRemoveDuplicates(
        //         new XDO_Tool_TrackingEventAssertOnce(
        //                 new XDO_Tool_TrackingEventRemoveEdits(
        //                         new XDO_Tool_TrackingEventFinalizer())));
    }
}