// ============================================
// RDQA Demo — Simulated Data
// Generic anonymised data for demonstration
// ============================================

export const facilities = [
  // District A (Urban) Facilities
  { id: 'UA-001', name: 'Facility A1', district: 'District A (Urban)', type: 'HC IV' },
  { id: 'UA-002', name: 'Facility A2', district: 'District A (Urban)', type: 'HC III' },
  { id: 'UA-003', name: 'Facility A3', district: 'District A (Urban)', type: 'HC III' },
  { id: 'UA-004', name: 'Facility A4', district: 'District A (Urban)', type: 'HC III' },
  { id: 'UA-005', name: 'Facility A5', district: 'District A (Urban)', type: 'HC III' },
  { id: 'UA-006', name: 'Facility A6', district: 'District A (Urban)', type: 'HC II' },
  // District B (Peri-Urban) Facilities
  { id: 'PU-001', name: 'Facility B1', district: 'District B (Peri-Urban)', type: 'Hospital' },
  { id: 'PU-002', name: 'Facility B2', district: 'District B (Peri-Urban)', type: 'HC IV' },
  { id: 'PU-003', name: 'Facility B3', district: 'District B (Peri-Urban)', type: 'HC IV' },
  { id: 'PU-004', name: 'Facility B4', district: 'District B (Peri-Urban)', type: 'HC III' },
  { id: 'PU-005', name: 'Facility B5', district: 'District B (Peri-Urban)', type: 'HC III' },
  { id: 'PU-006', name: 'Facility B6', district: 'District B (Peri-Urban)', type: 'HC III' },
];

export const indicators = [
  { id: 'fp', name: 'Family Planning', short: 'FP', register: 'HMIS 071' },
  { id: 'hts', name: 'HIV Testing Services', short: 'HTS', register: 'HMIS 080/081' },
  { id: 'anc', name: 'ANC First Visit', short: 'ANC1', register: 'HMIS 074' },
  { id: 'imm', name: 'Immunisation (DPT3)', short: 'DPT3', register: 'HMIS 055B' },
  { id: 'sgbv', name: 'SGBV Referrals', short: 'SGBV', register: 'HMIS 031' },
];

// Verification Factor data by facility and indicator
// VF = (Recounted / Reported) x 100%
export const verificationFactors = {
  'UA-001': { fp: 98, hts: 102, anc: 95, imm: 106, sgbv: 88 },
  'UA-002': { fp: 104, hts: 85, anc: 110, imm: 97, sgbv: 92 },
  'UA-003': { fp: 112, hts: 96, anc: 101, imm: 94, sgbv: 105 },
  'UA-004': { fp: 93, hts: 108, anc: 87, imm: 103, sgbv: 99 },
  'UA-005': { fp: 100, hts: 115, anc: 96, imm: 91, sgbv: 78 },
  'UA-006': { fp: 107, hts: 92, anc: 118, imm: 99, sgbv: 95 },
  'PU-001': { fp: 95, hts: 99, anc: 103, imm: 96, sgbv: 101 },
  'PU-002': { fp: 88, hts: 106, anc: 92, imm: 108, sgbv: 97 },
  'PU-003': { fp: 102, hts: 94, anc: 97, imm: 113, sgbv: 85 },
  'PU-004': { fp: 111, hts: 89, anc: 105, imm: 72, sgbv: 104 },
  'PU-005': { fp: 96, hts: 103, anc: 99, imm: 101, sgbv: 108 },
  'PU-006': { fp: 105, hts: 97, anc: 91, imm: 95, sgbv: 116 },
};

// Systems Assessment Scores (1-5 Likert scale across 5 functional areas)
export const systemsAssessment = {
  axes: [
    'M&E Structure',
    'Data Collection',
    'Indicator Definitions',
    'Data Management',
    'Data Use'
  ],
  'UA-001': [4.2, 3.8, 4.5, 3.5, 3.0],
  'UA-002': [3.0, 2.5, 3.8, 2.8, 2.2],
  'UA-003': [3.5, 4.0, 3.2, 3.8, 3.5],
  'UA-004': [2.8, 3.2, 4.0, 2.5, 2.8],
  'UA-005': [4.0, 3.5, 4.2, 4.0, 3.8],
  'UA-006': [3.2, 2.8, 3.5, 3.0, 2.5],
  'PU-001': [4.5, 4.2, 4.8, 4.0, 3.5],
  'PU-002': [3.8, 3.0, 4.0, 3.2, 2.8],
  'PU-003': [3.5, 3.8, 3.5, 3.5, 3.2],
  'PU-004': [2.5, 2.2, 3.0, 2.0, 1.8],
  'PU-005': [4.0, 3.5, 4.5, 3.8, 3.5],
  'PU-006': [3.0, 3.2, 3.8, 2.8, 2.5],
};

// Root cause distribution (percentage across all facilities)
export const rootCauses = [
  {
    category: 'Human Factors',
    percentage: 32,
    color: 'var(--cb-pink)',
    colorHex: '#E78AC3',
    examples: [
      'Staff attitude toward data recording',
      'High turnover of trained personnel',
      'Competing clinical priorities over documentation'
    ]
  },
  {
    category: 'Systems/Process',
    percentage: 28,
    color: 'var(--cb-green)',
    colorHex: '#A6D854',
    examples: [
      'Transcription errors between registers and summaries',
      'Misunderstanding of digital platform data entry',
      'Unclear indicator definitions across systems'
    ]
  },
  {
    category: 'Supply/Resources',
    percentage: 22,
    color: 'var(--cb-yellow)',
    colorHex: '#FFD92F',
    examples: [
      'Stock-outs of HMIS registers and tally sheets',
      'Connectivity issues affecting digital platform sync',
      'Lack of dedicated data storage space'
    ]
  },
  {
    category: 'Intentional',
    percentage: 8,
    color: 'var(--cb-brown)',
    colorHex: '#E5C494',
    examples: [
      'Selective reporting to meet targets',
      'Data fabrication in monthly summaries',
      'Omission of incomplete service records'
    ]
  },
  {
    category: 'Contextual/External',
    percentage: 10,
    color: 'var(--cb-grey)',
    colorHex: '#B3B3B3',
    examples: [
      'Donor funding shifts affecting staffing',
      'New MoH reporting requirements mid-quarter',
      'Disease outbreak diverting resources'
    ]
  }
];

// Timeline data for monthly RDQA cycle
export const timelinePhases = [
  {
    name: 'Pre-Visit Preparation',
    days: '1-3',
    start: 1,
    end: 3,
    color: 'var(--cb-purple)',
    colorHex: '#8DA0CB',
    tasks: [
      'Receive facility list & indicator priorities from client',
      'Desk review of digital platform & DHIS2 data',
      'Coordinate with district health teams for joint visits',
      'Pre-load KoboToolbox instruments',
      'Review previous month action points'
    ]
  },
  {
    name: 'On-Site RDQA Execution',
    days: '4-18',
    start: 4,
    end: 18,
    color: 'var(--cb-teal)',
    colorHex: '#66C2A5',
    tasks: [
      'Deploy field audit sub-teams (2-3 per facility)',
      'Extract & recount from HMIS registers',
      'Compute Verification Factors per indicator',
      'Photograph register pages as evidence',
      'Conduct root cause interviews',
      'Provide on-the-spot verbal feedback'
    ]
  },
  {
    name: 'Analysis & Reporting',
    days: '19-25',
    start: 19,
    end: 25,
    color: 'var(--cb-orange)',
    colorHex: '#FC8D62',
    tasks: [
      'Clean & validate KoboToolbox field data',
      'Compute final Verification Factors',
      'Generate facility scorecards & spider charts',
      'Compile Individual Facility Reports',
      'Update Action Point Tracker',
      'Submit final reports to client by the 25th'
    ]
  }
];

// Triangulation flow data (for Sankey diagram)
export const triangulationData = {
  nodes: [
    { id: 'digital', name: 'Digital Platform', desc: 'Real-time digital records from client systems' },
    { id: 'hmis', name: 'Facility Registers', desc: 'Primary HMIS registers (031, 055B, 071, 074, 080/081)' },
    { id: 'dhis2', name: 'National DHIS2', desc: 'District-level aggregate data from HMIS 105 reports' },
    { id: 'verify', name: 'Cross-Verification', desc: 'Three-way data comparison & VF computation' },
    { id: 'output', name: 'Verified Data', desc: 'Accurate, complete, and actionable programme data' }
  ],
  links: [
    { source: 'digital', target: 'verify', value: 35 },
    { source: 'hmis', target: 'verify', value: 40 },
    { source: 'dhis2', target: 'verify', value: 25 },
    { source: 'verify', target: 'output', value: 100 }
  ]
};

// Helper: get VF status
export function getVFStatus(vf) {
  if (vf >= 90 && vf <= 110) return 'acceptable';
  if (vf < 90) return 'over-reporting';
  return 'under-reporting';
}

// Helper: get VF color
export function getVFColor(vf) {
  if (vf >= 90 && vf <= 110) return '#66C2A5'; // teal
  if (vf < 90) return '#FC8D62'; // orange
  return '#8DA0CB'; // purple
}

// Helper: get aggregated VF for a facility
export function getFacilityAvgVF(facilityId) {
  const vfs = verificationFactors[facilityId];
  const values = Object.values(vfs);
  return Math.round(values.reduce((a, b) => a + b, 0) / values.length);
}

// Helper: compute district statistics
export function getDistrictStats(district) {
  const distFacilities = facilities.filter(f => f.district === district);
  const allVFs = [];
  distFacilities.forEach(f => {
    Object.values(verificationFactors[f.id]).forEach(v => allVFs.push(v));
  });
  const avg = Math.round(allVFs.reduce((a, b) => a + b, 0) / allVFs.length);
  const withinTolerance = allVFs.filter(v => v >= 90 && v <= 110).length;
  const pctWithin = Math.round((withinTolerance / allVFs.length) * 100);
  return { avg, pctWithin, total: allVFs.length, withinTolerance };
}
