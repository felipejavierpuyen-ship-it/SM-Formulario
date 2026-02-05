import { LightningElement, api, wire } from 'lwc';
import getAccionistas from '@salesforce/apex/WizardArriendosController.getPartPolizaAccionistas';

export default class FormularioSeccionSARLAFTAcci extends LightningElement {
    //@track shareholders = [{ id: 1, tipoDocumento: '', numeroDocumento: '', nombreCompleto: '', participacion: '', cotizaEnBolsa: 'No', esPEP: 'No', tributaOtroPais: 'No' }];
    @api recordId;
    shareholders = [];
    nextShareholderId = 1;

    yesNoOptions = [
        { label: 'Sí', value: 'Si' },
        { label: 'No', value: 'No' }
    ];

    documentTypeOptions = [
        { label: 'Cédula de Ciudadanía', value: 'Cédula de ciudadanía' },
        { label: 'NIT', value: 'NIT' },
        { label: 'Cédula de Extranjería', value: 'Cédula Extranjería' }
    ];

    connectedCallback() {
        console.log('revisar recordId: '+this.recordId);
        if (this.recordId) {
            this.loadShareholders();
        }
    }

    async loadShareholders() {
        try {
            const result = await getAccionistas({ caseId: this.recordId });
            if (result && result.length > 0) {
                console.log('revisar: '+ result);
                this.shareholders = result.map((record, index) => ({
                    id: index + 1,
                    tipoDocumento: record.Tipo_de_Documento__c,
                    numeroDocumento: record.Cedula_o_NIT__c
                    /*nombreCompleto: record.NombreCompleto__c,
                    participacion: record.Participacion__c,
                    cotizaEnBolsa: record.CotizaEnBolsa__c ? 'Si' : 'No',
                    esPEP: record.EsPEP__c ? 'Si' : 'No',
                    tributaOtroPais: record.TributaOtroPais__c ? 'Si' : 'No'*/
                }));
                this.nextShareholderId = this.shareholders.length + 1;
            } else {
                this.addEmptyRow();
            }
        } catch (error) {
            console.error('Error al cargar accionistas', error);
            this.addEmptyRow();
        }
    }

    addEmptyRow() {
        this.shareholders = [{
            id: 1,
            tipoDocumento: '',
            numeroDocumento: '',
            nombreCompleto: '',
            participacion: '',
            cotizaEnBolsa: 'NO',
            esPEP: 'NO',
            tributaOtroPais: 'NO'
        }];
        this.nextShareholderId = 2;
    }

    addShareholder(){
        this.shareholders = [...this.shareholders, {
            id: this.nextShareholderId++,
            tipoDocumento: '',
            numeroDocumento: '',
            nombreCompleto: '',
            participacion: '',
            cotizaEnBolsa: 'No',
            esPEP: 'No',
            tributaOtroPais: 'No'
        }];
    }

    handleShareholderChange(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.detail.value;

        this.shareholders = this.shareholders.map(sh => {
            if (sh.id == id) {
                return { ...sh, [field]: value };
            }
            return sh;
        });
        this.notifyDataChange();
    }

    notifyDataChange() {
        this.dispatchEvent(new CustomEvent('formdataupdate', {
            detail: { data: { accionistas: this.shareholders } }
        }));
    }

    handlePrevious() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('next', {
            detail: { data: { accionistas: this.shareholders } }
        }));
    }
}