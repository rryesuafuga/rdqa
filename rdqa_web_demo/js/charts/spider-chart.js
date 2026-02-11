// ============================================
// D3.js Radar/Spider Chart — Systems Assessment
// ============================================
import { facilities, systemsAssessment } from '../data.js';

export function renderSpiderChart(containerId, facilityId = 'KLA-001', compareId = null) {
  const container = document.getElementById(containerId);
  if (!container) return;

  container.innerHTML = '';

  const size = Math.min(container.clientWidth, 450);
  const margin = 60;
  const radius = (size / 2) - margin;
  const levels = 5;
  const axes = systemsAssessment.axes;
  const total = axes.length;
  const angleSlice = (Math.PI * 2) / total;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${size} ${size}`)
    .attr('preserveAspectRatio', 'xMidYMid meet')
    .attr('role', 'img')
    .attr('aria-label', `Systems Assessment radar chart for facility ${facilityId}`)
    .append('g')
    .attr('transform', `translate(${size / 2},${size / 2})`);

  const rScale = d3.scaleLinear()
    .domain([0, 5])
    .range([0, radius]);

  // Grid levels
  for (let level = 1; level <= levels; level++) {
    const r = (radius / levels) * level;
    const points = [];
    for (let i = 0; i < total; i++) {
      points.push([
        r * Math.cos(angleSlice * i - Math.PI / 2),
        r * Math.sin(angleSlice * i - Math.PI / 2)
      ]);
    }
    svg.append('polygon')
      .attr('points', points.map(p => p.join(',')).join(' '))
      .attr('fill', 'none')
      .attr('stroke', '#e2e8f0')
      .attr('stroke-width', level === levels ? 1.5 : 0.5);

    // Level label
    svg.append('text')
      .attr('x', 5)
      .attr('y', -r + 4)
      .attr('font-size', '9px')
      .attr('fill', '#94a3b8')
      .text(level);
  }

  // Axis lines and labels
  axes.forEach((axis, i) => {
    const angle = angleSlice * i - Math.PI / 2;
    const lineEnd = radius + 10;

    svg.append('line')
      .attr('x1', 0).attr('y1', 0)
      .attr('x2', lineEnd * Math.cos(angle))
      .attr('y2', lineEnd * Math.sin(angle))
      .attr('stroke', '#cbd5e1')
      .attr('stroke-width', 0.8);

    const labelR = radius + 30;
    const lx = labelR * Math.cos(angle);
    const ly = labelR * Math.sin(angle);

    svg.append('text')
      .attr('x', lx)
      .attr('y', ly)
      .attr('text-anchor', Math.abs(lx) < 5 ? 'middle' : lx > 0 ? 'start' : 'end')
      .attr('dominant-baseline', Math.abs(ly) < 5 ? 'middle' : ly > 0 ? 'hanging' : 'auto')
      .attr('font-size', '11px')
      .attr('font-weight', '600')
      .attr('fill', '#4a5568')
      .text(axis);
  });

  // Draw data polygon
  function drawDataArea(data, color, opacity, patternClass) {
    const points = data.map((val, i) => {
      const angle = angleSlice * i - Math.PI / 2;
      return [
        rScale(val) * Math.cos(angle),
        rScale(val) * Math.sin(angle)
      ];
    });

    // Filled area
    svg.append('polygon')
      .attr('points', points.map(p => '0,0').join(' '))
      .attr('fill', color)
      .attr('fill-opacity', opacity)
      .attr('stroke', color)
      .attr('stroke-width', 2.5)
      .attr('stroke-opacity', 0.9)
      .transition()
      .duration(1000)
      .attr('points', points.map(p => p.join(',')).join(' '));

    // Data points
    data.forEach((val, i) => {
      const angle = angleSlice * i - Math.PI / 2;
      svg.append('circle')
        .attr('cx', 0)
        .attr('cy', 0)
        .attr('r', 5)
        .attr('fill', color)
        .attr('stroke', '#fff')
        .attr('stroke-width', 2)
        .transition()
        .duration(1000)
        .attr('cx', rScale(val) * Math.cos(angle))
        .attr('cy', rScale(val) * Math.sin(angle));

      // Value label
      const labelR2 = rScale(val) + 15;
      svg.append('text')
        .attr('x', labelR2 * Math.cos(angle))
        .attr('y', labelR2 * Math.sin(angle))
        .attr('text-anchor', 'middle')
        .attr('dominant-baseline', 'middle')
        .attr('font-size', '10px')
        .attr('font-weight', '700')
        .attr('fill', color)
        .attr('opacity', 0)
        .text(val.toFixed(1))
        .transition()
        .duration(1000)
        .attr('opacity', 1);
    });
  }

  // Primary facility
  const primaryData = systemsAssessment[facilityId] || [3, 3, 3, 3, 3];
  drawDataArea(primaryData, '#1B9E77', 0.15);

  // Comparison facility
  if (compareId && systemsAssessment[compareId]) {
    drawDataArea(systemsAssessment[compareId], '#7570B3', 0.1);
  }
}
