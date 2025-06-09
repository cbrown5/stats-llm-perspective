# Notes

@mondal2024evaluating - This study found high accuracy across 27 statistical vignettes. However, the vignettes are not provided, they only cite earlier studies So not including in citations as the study isn't replicable and we don't know what the LLM agents were tested against. Further, there was apparently no replication of prompts, each vignette was only tested once. 

```{r risk-framework, fig.width=5, fig.height=3, dpi=300, echo = FALSE}

library(DiagrammeR)

# Create a decision tree diagram for statistical risk mitigation
DiagrammeR::grViz("
digraph risk_framework {
  # Graph settings
  graph [rankdir = TD, fontname = 'Arial', nodesep = 0.8, ranksep = 0.5]
  node [shape = rectangle, fontname = 'Arial', fontsize = 12, style = 'filled', 
        fillcolor = 'white', width = 3, height = 0.8, margin = 0.2]
  edge [fontname = 'Arial', fontsize = 10]

  # Decision nodes
  task_complexity [label = 'Assess Task Complexity', fillcolor = '#e6f3ff', shape = diamond]
  error_consequence_low [label = 'Assess Consequence of Errors\n(Low Complexity)', fillcolor = '#e6f3ff', shape = diamond]
  error_consequence_high [label = 'Assess Consequence of Errors\n(High Complexity)', fillcolor = '#e6f3ff', shape = diamond]
  
  # Risk levels and mitigation strategies
  low_risk [label = 'Low Risk\n- Use standard prompts\n- Basic verification', fillcolor = '#ccffcc']
  medium_risk1 [label = 'Medium Risk\n- Provide rich context\n- Use Chain of Thought\n- Compare multiple approaches', fillcolor = '#ffffcc']
  medium_risk2 [label = 'Medium Risk\n- Expert review required\n- Include domain knowledge\n- Request self-evaluation', fillcolor = '#ffffcc']
  high_risk [label = 'High Risk\n- Use LLM for code only\n- Human decision-making\n- Peer review essential\n- Extensive validation', fillcolor = '#ffcccc']
  
  # Connections
  task_complexity -> error_consequence_low [label = 'Low\n(Descriptive stats,\nbasic plotting,\nsimple tests)']
  task_complexity -> error_consequence_high [label = 'High\n(Complex models,\nmultivariate analysis,\nspecialized methods)']
  
  error_consequence_low -> low_risk [label = 'Low\n(Exploratory,\nnon-critical)']
  error_consequence_low -> medium_risk1 [label = 'High\n(Publication,\ndecision-making)']
  
  error_consequence_high -> medium_risk2 [label = 'Low\n(Exploratory,\nnon-critical)']
  error_consequence_high -> high_risk [label = 'High\n(Publication,\ndecision-making)']
  
  # Additional guidance nodes
  subgraph cluster_guidance {
    label = 'General Risk Mitigation Guidelines'
    style = filled
    fillcolor = '#f0f0f0'
    node [shape = box, margin = 0.1, fontsize = 10, width = 2.5]
    
    guidance1 [label = 'Always document LLM use\nand prompting strategies']
    guidance2 [label = 'Validate against established\nstatistical literature']
    guidance3 [label = 'Consider reproducibility\nand transparency']
    
    guidance1 -> guidance2 -> guidance3 [style = invis]
  }
}
")
```
<!-- CUT THIS FIGURE< NOT THAT HELPFUL??? --> 
**Figure XXX**
Decision tree showing how to identify and mitigate risks in LLM statistical advice based on task complexity and consequence of errors.