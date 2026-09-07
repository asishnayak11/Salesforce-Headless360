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
     @date          27/12/2023

     TODO:
 */

public with sharing class XDO_Tool_NullOrEmptyArgumentException extends Exception {

    public XDO_Tool_NullOrEmptyArgumentException(String field, String arg) {
        setMessage('The field "' + field + '" cannot be empty.');
    }
}