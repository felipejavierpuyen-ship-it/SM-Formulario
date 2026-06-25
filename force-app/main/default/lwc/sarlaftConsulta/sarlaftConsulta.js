import { LightningElement } from 'lwc';
import consultar from '@salesforce/apex/SarlaftServiceLWC.consultar';
import hasPermission from '@salesforce/customPermission/Ver_Formulario_Sarlaft';

export default class SarlaftConsulta extends LightningElement {
  documentType = 'CC';
  documentNumber = '';
  result;
  errorMessage;
  isLoading = false;
  canViewForm = hasPermission;//permiso para ver documento

  documentTypeOptions = [
    { label: 'Cédula de ciudadanía', value: 'CC' },
    { label: 'NIT', value: 'NIT' },
    { label: 'Cédula extranjera', value: 'CE' },
    { label: 'Pasaporte', value: 'PA' }
  ];

  handleChange(event) {
    this[event.target.name] = event.target.value;
  }
handleEnter(event) {
    if(event.key === 'Enter'){
        this.handleConsultar();
    }
}
  async handleConsultar() {
    this.errorMessage = null;
    this.result = null;

    if (!this.documentNumber) {
      this.errorMessage = 'El número de documento es obligatorio.';
      return;
    }

    this.isLoading = true;

    try {
      const response = await consultar({
        documentNumber: this.documentNumber,
        documentType: this.documentType
      });

      this.result = response;
      if (!response) this.errorMessage = 'No se recibió respuesta del servicio.';

    } catch (e) {
      this.errorMessage = e?.body?.message || e?.message || 'Error inesperado al consultar.';
    } finally {
      this.isLoading = false;
    }
  }
}