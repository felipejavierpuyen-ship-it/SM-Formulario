import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class FlexcardFilePreviewer extends NavigationMixin(OmniscriptBaseMixin(LightningElement)) {
    @api fileId;

    handlePreview() {
        if (this.fileId) {
            // Usamos 'standard__namedPage' para forzar el Previewer
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    // Pasamos el ID del archivo en el estado
                    recordIds: this.fileId, 
                    selectedRecordId: this.fileId
                }
            });
        } else {
            console.error('No se recibió un fileId válido para el preview.');
        }
    }
}