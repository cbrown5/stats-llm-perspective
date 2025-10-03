library(DiagrammeR)

DiagrammeR::grViz("
digraph workflow {
  # Graph settings
  graph [rankdir = TD, fontname = 'Arial', nodesep = 0.8, ranksep = 0.8]
  node [shape = rectangle, fontname = 'Arial', fontsize = 20, style = 'filled', 
        fillcolor = 'white', margin = 0.2]
  edge [fontname = 'Arial', fontsize = 10]

  # Main workflow steps
  step1 [label = 'Step 1: Select statistical analysis', fillcolor = '#e6f3ff', width = 3, height = 0.8]
  step2 [label = 'Step 2: Plan implementation', fillcolor = '#e6f3ff', width = 3, height = 0.8]
  step3 [label = 'Step 3: Write code', fillcolor = '#e6f3ff', width = 3, height = 0.8]
  
  # Recommendations for each step
  rec1 [label = 'Recommendations:\\n• Explore multiple analytical approaches\\n• Provide domain knowledge, data and relevant literature\\n• Combine domain knowledge with step-by-step reasoning (Chain of Thought)\\n• Compare statistical approaches with alternatives\\n• Verify against statistical textbooks and guidelines', 
        shape = 'box', fillcolor = '#f0f8ff', width = 6]
        
  rec2 [label = 'Recommendations:\\n• Create a detailed README with analysis context\\n• Define clear research questions and hypotheses\\n• Create an organized and modular project directory\\n• Specify data characteristics and structure\\n• Outline analytical constraints and assumptions\\n• Plan workflow before implementation\\n• Use CoT reasoning', 
        shape = 'box', fillcolor = '#f0f8ff', width = 6]
        
  rec3 [label = 'Recommendations:\\n• Provide implementation constraints (packages, style)\\n• Request modular, well-documented code\\n• Include verification and diagnostic steps\\n• Add comments explaining statistical and implementation \n• Define clear research questions and hypotheses', 
        shape = 'box', fillcolor = '#f0f8ff', width = 6]

  # Connections between steps
  step1 -> step2 -> step3 [weight = 5]
  
  # Connect steps to their recommendations
  step1 -> rec1 [dir = none, style = dashed]
  step2 -> rec2 [dir = none, style = dashed]  
  step3 -> rec3 [dir = none, style = dashed]
  
  # Human oversight element
  {rank = same; human [label = 'Human Oversight\\nand Evaluation', 
                      shape = 'oval', fillcolor = '#0a81f8', 
                      style = 'filled,dashed', width = 3]}
                      
  human -> step1 [dir = both, style = dashed, constraint = false]
  human -> step2 [dir = both, style = dashed, constraint = false]
  human -> step3 [dir = both, style = dashed, constraint = false]
}
")

