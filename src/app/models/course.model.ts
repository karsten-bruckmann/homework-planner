export interface Material {
  id: string;
  name: string;
  type: 'book' | 'workbook' | 'other';
}

export interface Course {
  id: string;
  name: string;
  color?: string;
  materials: Material[];
}