// ============================================
// D3.js Grouped Bar Chart — Kampala vs Wakiso
// ============================================
import { facilities, indicators, verificationFactors, getVFColor } from '../data.js';

export function renderDistrictCompare(containerId, indicatorId = 'fp') {
  const container = document.getElementById(containerId);
  if (!container) return;

  container.innerHTML = '';

  const margin = { top: 30, right: 30, bottom: 60, left: 60 };
  const width = container.clientWidth - margin.left - margin.right;
  const height = 360 - margin.top - margin.bottom;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width + margin.left + margin.right} ${height + margin.top + margin.bottom}`)
    .attr('preserveAspectRatio', 'xMidYMid meet')
    .attr('role', 'img')
    .attr('aria-label', `Kampala vs Wakiso comparison for ${indicatorId}`)
    .append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`);

  // Defs for patterns
  const defs = svg.append('defs');
  defs.append('pattern')
    .attr('id', 'diag-district-a')
    .attr('patternUnits', 'userSpaceOnUse')
    .attr('width', 6).attr('height', 6)
    .append('path')
    .attr('d', 'M0,6 L6,0')
    .attr('stroke', '#1B9E77')
    .attr('stroke-width', 1.5);

  defs.append('pattern')
    .attr('id', 'diag-district-b')
    .attr('patternUnits', 'userSpaceOnUse')
    .attr('width', 6).attr('height', 6)
    .append('circle')
    .attr('cx', 3).attr('cy', 3).attr('r', 1.5)
    .attr('fill', '#7570B3');

  // Prepare data: avg VF per indicator per district
  const districts = ['District A (Urban)', 'District B (Peri-Urban)'];
  const data = indicators.map(ind => {
    const result = { indicator: ind.short, fullName: ind.name };
    districts.forEach(dist => {
      const distFacilities = facilities.filter(f => f.district === dist);
      const vfs = distFacilities.map(f => verificationFactors[f.id][ind.id]);
      result[dist] = Math.round(vfs.reduce((a, b) => a + b, 0) / vfs.length);
    });
    return result;
  });

  const x0 = d3.scaleBand()
    .domain(data.map(d => d.indicator))
    .range([0, width])
    .padding(0.3);

  const x1 = d3.scaleBand()
    .domain(districts)
    .range([0, x0.bandwidth()])
    .padding(0.1);

  const y = d3.scaleLinear()
    .domain([70, 120])
    .range([height, 0]);

  const colors = { 'District A (Urban)': '#1B9E77', 'District B (Peri-Urban)': '#7570B3' };
  const shortLabels = { 'District A (Urban)': 'Urban', 'District B (Peri-Urban)': 'Peri-Urban' };

  // Tolerance band
  svg.append('rect')
    .attr('x', 0).attr('y', y(110))
    .attr('width', width).attr('height', y(90) - y(110))
    .attr('fill', '#66C2A5').attr('opacity', 0.06).attr('rx', 4);

  // 100% line
  svg.append('line')
    .attr('x1', 0).attr('x2', width)
    .attr('y1', y(100)).attr('y2', y(100))
    .attr('stroke', '#1a365d').attr('stroke-dasharray', '4,4').attr('opacity', 0.3);

  // Grid
  [80, 90, 100, 110].forEach(val => {
    svg.append('line')
      .attr('x1', 0).attr('x2', width)
      .attr('y1', y(val)).attr('y2', y(val))
      .attr('stroke', '#e2e8f0').attr('stroke-width', 0.5);
  });

  // Bars
  const groups = svg.selectAll('.group')
    .data(data)
    .enter()
    .append('g')
    .attr('transform', d => `translate(${x0(d.indicator)},0)`);

  districts.forEach((dist, di) => {
    groups.append('rect')
      .attr('x', x1(dist))
      .attr('width', x1.bandwidth())
      .attr('y', height)
      .attr('height', 0)
      .attr('fill', colors[dist])
      .attr('rx', 3)
      .transition()
      .duration(800)
      .delay((d, i) => i * 80 + di * 100)
      .attr('y', d => y(d[dist]))
      .attr('height', d => height - y(d[dist]));

    // Pattern overlay
    groups.append('rect')
      .attr('x', x1(dist))
      .attr('width', x1.bandwidth())
      .attr('y', d => y(d[dist]))
      .attr('height', d => height - y(d[dist]))
      .attr('fill', `url(#diag-district-${di === 0 ? 'a' : 'b'})`)
      .attr('opacity', 0.25)
      .attr('rx', 3)
      .attr('pointer-events', 'none');

    // Value labels
    groups.append('text')
      .attr('x', x1(dist) + x1.bandwidth() / 2)
      .attr('y', d => y(d[dist]) - 6)
      .attr('text-anchor', 'middle')
      .attr('font-size', '11px')
      .attr('font-weight', '700')
      .attr('fill', colors[dist])
      .attr('opacity', 0)
      .text(d => d[dist] + '%')
      .transition()
      .duration(600)
      .delay((d, i) => i * 80 + di * 100 + 400)
      .attr('opacity', 1);
  });

  // X Axis
  svg.append('g')
    .attr('transform', `translate(0,${height})`)
    .call(d3.axisBottom(x0))
    .selectAll('text')
    .attr('font-size', '11px')
    .attr('font-weight', '600')
    .attr('fill', '#4a5568');

  // Y Axis
  svg.append('g')
    .call(d3.axisLeft(y).ticks(6).tickFormat(d => d + '%'))
    .selectAll('text')
    .attr('font-size', '10px')
    .attr('fill', '#4a5568');

  // Legend
  const legend = svg.append('g')
    .attr('transform', `translate(${width - 180}, -15)`);

  districts.forEach((dist, i) => {
    const lg = legend.append('g')
      .attr('transform', `translate(${i * 100}, 0)`);
    lg.append('rect')
      .attr('width', 14).attr('height', 14)
      .attr('fill', colors[dist]).attr('rx', 3);
    lg.append('text')
      .attr('x', 20).attr('y', 11)
      .attr('font-size', '11px').attr('font-weight', '600')
      .attr('fill', '#4a5568')
      .text(shortLabels[dist] || dist);
  });
}
