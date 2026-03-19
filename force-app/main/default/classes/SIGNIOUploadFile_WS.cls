global without sharing class SIGNIOUploadFile_WS implements vlocity_ins.VlocityOpenInterface2 {
    global Object invokeMethod(
        String method,
        Map<String, Object> input,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        // Initialize success status
        system.debug(method);
        system.debug(input);
        if (method == 'uploadFile') {
            // Extract parentProductId from the input map
            String caseId = (String) input.get('CaseId');
            String idTransaccion = (String) input.get('IdTransaccion');
            String roles = (String) input.get('Roles');

            // Call the helper method to get the child product attributes
            uploadFile(caseId, idTransaccion, roles, outMap);
            return outMap;
        }
        return null;
    }
    
    public static void cargasDocumento(){
        
        Attachment recordAttachment = [SELECT ID FROM Attachment];
        String boundary = '----------------------------741e90d31eff';
        String header = '--'
            +boundary
            +'\r\nContent-Disposition: form-data; name="file"; filename="'
            +recordAttachment.Name
            +'"\r\nContent-Type: application/octet-stream';
        String footer = '\r\n--'+boundary+'--';              
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        while(headerEncoded.endsWith('=')){
            header+=' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        }
        String bodyEncoded = EncodingUtil.base64Encode(recordAttachment.Body);
        String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        
        Blob bodyBlob = null;
        String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
        if(last4Bytes.endsWith('=')){
            Blob decoded4Bytes = EncodingUtil.base64Decode(last4Bytes);
            HttpRequest tmp = new HttpRequest();
            tmp.setBodyAsBlob(decoded4Bytes);
            String last4BytesFooter = tmp.getBody()+footer;   
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded.substring(0,bodyEncoded.length()-4)+EncodingUtil.base64Encode(Blob.valueOf(last4BytesFooter)));
        }
        else{
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
        }
    }
    
    public static void uploadFile(String caseId, String idTransaccion, String roles, Map<String, Object> outMap) {
        //caseId = '500Ek00000eFyb9IAC';
        //idTransaccion = '60b50f7c-d795-4453-bf23-f9db44d1be2d';
        Case cs = [SELECT Id, CaseNumber FROM Case WHERE Id =: caseId];
        List<ContentDocumentLink> lstCDL = [SELECT Id, LinkedEntityId, ContentDocumentId 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId =: caseId];
        List<Id> lstCDId = new List<Id>();
        for(ContentDocumentLink cdl : lstCDL){
            lstCDId.add(cdl.ContentDocumentId);
        }
        
        String pdfName = 'CONTRATO_' + cs.CaseNumber;
        List<ContentDocument> lstCD = [SELECT Id, Title, ParentId, LatestPublishedVersionId, CreatedDate
                                       FROM ContentDocument
                                       WHERE Id IN: lstCDId
                                       AND Title =: pdfName
                                       ORDER BY CreatedDate DESC];
        
        if(lstCD.size() > 0){
            ContentVersion recordAttachment = [SELECT Id, VersionData, Title 
                                               FROM ContentVersion 
                                               WHERE ID =: lstCD[0].ParentId
                                               ORDER BY CreatedDate DESC];
            String fileName = pdfName + '.pdf';
            Blob fileBlob = recordAttachment.VersionData;
            
            Blob bodyBlob = formatBlob(idTransaccion, fileName, fileBlob);
            
            String token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI1IiwianRpIjoiZjhlMzdlNjY2MWUzYjQzM2IzMWMwZjBkMDg5Y2MzNmRhNDllNGVlNDVjY2RiYWU1Y2I0MzkxYzM1NmU3MmY5Nzk3ZGEzYmVmMjAzNGFjMmYiLCJpYXQiOjE3NzM3ODQ1NjguNTk5OTU1LCJuYmYiOjE3NzM3ODQ1NjguNTk5OTU4LCJleHAiOjE4MDUzMjA1NjguNTkyNzcxLCJzdWIiOiJkZjBiODgwNy1kYWI3LTRhMWMtOWU4OS1mMWFmNWY1NmY4ODkiLCJzY29wZXMiOltdfQ.O4jz3cNDjGm_qjtKx9DHq1OPE_TfPavNJ2y4ekph2GCx3f5q8iI_m8q6dqxgzNXpKiH4y0qcXgTkJQq2_4fMvJQn8ocMw_aTrdfPLbesOY5YXrScx0ssWXEUkcHMEz47ibxuKuUwP6I93BWJtQ1sAa--1AT-Uwzs8Z8VA-UfSBg-VQUfhfGkFzF90MvPGokI1NPSLbVj74l8im-bx9DL8eC-yCKiLCpthCaUm7_GyIhhMvtYz0y722xHRPZuy86iA7AnAB_U5XlM9qaP7hRkOgdcziqsPD7v4SND1AgWT7NHecoseQTuJarOKrMmM4sbS-SF1wWQRU1VD62KlzBaKvNr41yabJ16vQhyjtr79bgwJwpklfq_t3UwvjPENWusOfa3VrjPvueIedG1c3lxSPjSvzqfmOjkXK-JXhc5Rn1eo9zfI8TpbyM1_HyXdk6NeKJ4aLVe7VbgxICXPwNorrQW1zNdGVkgdD_cmdAKBODD4FEIhLSNBIeTWuexqpW4JxsHklL7sLuJM5maS33rIYleUcbzl-C-HMbuSCyMIeyjkzjJvYfYal7r6C07f-gi6krrFPj1pu7GXVjlcSwiKesJ3zlmBeA9k5bq1d_jNvZiK7j47vFkyVUOi91KSe8X46aXDjgq78XmzVew6tYbm_InrHkX4vPZ_OBOMb4U84k';
            // 5. Configurar la petición HTTP
            Signio__c settings = Signio__c.getOrgDefaults();
            String endpoint = settings.Endpoint__c;
            String boundary = settings.Boundary__c;
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint + '/transacciones/cargar_documento');
                req.setMethod('POST');
                req.setHeader('Authorization', 'Bearer ' + token); // Reemplazar por token real
                req.setHeader('Accept', 'application/json');
                req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
                req.setBodyAsBlob(bodyBlob);
                req.setTimeout(120000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    system.debug('Success: '+res.getBody());
                    //outMap.put('Success', bodyBlob);
                } else {
                    system.debug('Succrroress: '+res.getBody());
                }
            } catch (Exception e) {
                
            }
        }
    }
    
    public static Blob formatBlob(String idTransaccion, String fileName, Blob fileBlob){
        Blob bodyBlob = null;
        Signio__c settings = Signio__c.getOrgDefaults();
        String roles = settings.Roles__c;
        
        // 1. Definir el Boundary (usamos uno estándar)
        String boundary = settings.Boundary__c;
        
        // 2. Construir el Header con los campos de texto ANTES del archivo
        String header = '--' + boundary + '\r\n' +
            'Content-Disposition: form-data; name="id_transaccion"\r\n\r\n' +
            idTransaccion + '\r\n' +
            '--' + boundary + '\r\n' +
            'Content-Disposition: form-data; name="roles"\r\n\r\n' +
            roles + '\r\n' +
            '--' + boundary + '\r\n' +
            'Content-Disposition: form-data; name="documento"; filename="' + fileName + '"\r\n' +
            'Content-Type: application/pdf\r\n\r\n'; // Importante: \r\n\r\n al final del header
        
        // Definir el Footer
        String footer = '\r\n--' + boundary + '--';
        
        // lógica de codificación Base64 (Mantenida para integridad del PDF)
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header));
        while(headerEncoded.endsWith('=')){
            header += ' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header));
        }
        
        String bodyEncoded = EncodingUtil.base64Encode(fileBlob);
        String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        String last4Bytes = bodyEncoded.substring(bodyEncoded.length() - 4, bodyEncoded.length());
        
        if(last4Bytes.endsWith('=')){
            Blob decoded4Bytes = EncodingUtil.base64Decode(last4Bytes);
            HttpRequest tmp = new HttpRequest();
            tmp.setBodyAsBlob(decoded4Bytes);
            String last4BytesFooter = tmp.getBody() + footer;   
            bodyBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded.substring(0, bodyEncoded.length() - 4) 
                                                 + EncodingUtil.base64Encode(Blob.valueOf(last4BytesFooter)));
        } else {
            bodyBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded + footerEncoded);
        }
        
        return bodyBlob;
    }
}