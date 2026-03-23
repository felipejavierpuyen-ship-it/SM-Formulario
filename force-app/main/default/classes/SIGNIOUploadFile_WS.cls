global without sharing class SIGNIOUploadFile_WS implements vlocity_ins.VlocityOpenInterface2 {
    global Object invokeMethod(
        String method,
        Map<String, Object> input,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        // Initialize success status
        if (method == 'uploadFile') {
            // Extract values from the input map
            String token = (String) input.get('Token');
            String caseId = (String) input.get('CaseId');
            String idTransaccion = (String) input.get('IdTransaccion');
            
            uploadFile(token, caseId, idTransaccion, outMap);
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
    
    public static void uploadFile(String token, String caseId, String idTransaccion, Map<String, Object> outMap) {
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
                                               WHERE ID =: lstCD[0].LatestPublishedVersionId
                                               ORDER BY CreatedDate DESC];
            String fileName = pdfName + '.pdf';
            Blob fileBlob = recordAttachment.VersionData;
            
            Blob bodyBlob = formatBlob(idTransaccion, fileName, fileBlob);
            
            // 5. Configurar la petición HTTP
            Signio__c settings = Signio__c.getOrgDefaults();
            String endpoint = settings.Endpoint__c;
            String boundary = settings.Boundary__c;
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint + '/transacciones/cargar_documento');
                req.setMethod('POST');
                req.setHeader('Authorization', 'Bearer ' + token);
                req.setHeader('Accept', 'application/json');
                req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
                req.setBodyAsBlob(bodyBlob);
                req.setTimeout(120000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                system.debug('Response: ' + res.getBody());
                
                SIGNIOResponse response = (SIGNIOResponse) JSON.deserialize(res.getBody(), SIGNIOResponse.class);
                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    outMap.put('success', true);
                    outMap.put('id_documento', response.id_documento);
                    outMap.put('message', response.mensaje);
                } else {
                    outMap.put('success', false);
                    outMap.put('message', 'Respuesta: ' + response.mensaje);
                }
            } catch (Exception e) {
                outMap.put('success', false);
                outMap.put('message', 'Ocurrió un error: ' + e.getMessage());
            }
        }else{
            outMap.put('success', false);
            outMap.put('message', 'No se encontró el archivo correspondiente');
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
    
    public class SIGNIOResponse {
        public String codigo;
        public String id_documento;
        public String mensaje;
    }
}