import LightningDatatable from 'lightning/datatable';
import picklistTemplate from './picklistTemplate.html';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        picklistType: { // Nombre del tipo personalizado
            template: picklistTemplate,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context']
        }
    };
}