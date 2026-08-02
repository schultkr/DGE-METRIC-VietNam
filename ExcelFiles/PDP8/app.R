# app.R
# Investment dashboard
# - robust column-name cleaning
# - filters: Plan, Technology, Year range
# - "Selected plan" KPI + plots (KPIs ALWAYS refer to the selected plan only)
# - view switch: KPIs & Plots vs Summary tables
# - summary tables aggregated BY PLAN for chosen time periods and technologies (+ optional Total)
# - numeric display: 2 digits after decimal (KPIs + DT tables)
#
# Improvements: technology-colored plots (Set2/Paired), value_box themes, loading spinners,
# Plots vs Summary tabs in KPI view, uncertainty bands per technology, shared plot theme.

library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
library(DT)
library(scales)

# Optional: load shinycssloaders for spinner (graceful fallback if not installed)
has_spinner <- requireNamespace("shinycssloaders", quietly = TRUE)
if (has_spinner) library(shinycssloaders)
maybe_spinner <- function(ui, ...) {
  if (has_spinner) shinycssloaders::withSpinner(ui, ...) else ui
}

# ---------- Data ----------
DATA_PATH <- "Investment.csv"   # put app.R in same folder as Investment.csv

raw <- read.csv(DATA_PATH, check.names = FALSE)

# ---- FIX BAD / EMPTY COLUMN NAMES ----
nms <- names(raw)
bad <- is.na(nms) | trimws(nms) == ""
if (any(bad)) nms[bad] <- paste0("X", which(bad))
names(raw) <- make.unique(nms, sep = "_")

# Drop columns that are entirely NA / empty strings
raw <- raw %>%
  select(where(~ !(all(is.na(.)) || all(trimws(as.character(.)) == ""))))

# Clean a common index column if present
if ("Unnamed: 0" %in% names(raw)) raw <- raw %>% select(-`Unnamed: 0`)

# Helpers
has_col <- function(df, nm) nm %in% names(df)
fmt_num <- function(x, digits = 2) {
  if (length(x) == 0) return("n/a")
  if (all(is.na(x))) return("n/a")
  formatC(x, format = "f", digits = digits, big.mark = ",")
}

# Ensure key columns exist
stopifnot(all(c("Technology", "Plan", "Year") %in% names(raw)))

# Coerce Year to integer
raw$Year <- suppressWarnings(as.integer(raw$Year))

# Shared plot theme: clean, readable, technology-colored lines
theme_dashboard <- function() {
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      legend.title = element_text(face = "bold"),
      axis.title = element_text(face = "bold"),
      plot.caption = element_text(color = "gray50", size = 10)
    )
}

# ---------- UI ----------
ui <- page_sidebar(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  title = "Investment Dashboard",
  sidebar = sidebar(
    width = 380,
    
    radioButtons(
      "view_mode", "Dashboard view",
      choices = c("KPIs & Plots" = "plots", "Summary tables" = "tables"),
      selected = "plots",
      inline = TRUE
    ),
    tags$hr(),
    
    tags$h5("Filters"),
    uiOutput("plan_ui"),
    uiOutput("tech_ui"),
    uiOutput("year_ui"),
    tags$hr(),
    
    # KPIs must refer to ONE selected plan, so we provide a selector
    uiOutput("plan_focus_ui"),
    
    tags$hr(),
    checkboxInput("show_uncertainty", "Show uncertainty bands (if available)", TRUE),
    
    tags$hr(),
    tags$h5("Summary settings"),
    selectInput(
      "period_scheme", "Time periods",
      choices = c(
        "Annual" = "annual",
        "PDP periods (2025-30, 2031-35, 2036-50)" = "pdp",
        "5-year bins" = "bin5",
        "10-year bins" = "bin10",
        "Custom breaks" = "custom"
      ),
      selected = "pdp"
    ),
    conditionalPanel(
      condition = "input.period_scheme == 'custom'",
      textInput("custom_breaks", "Custom year breaks (comma-separated)", value = "2025,2030,2035,2050"),
      helpText("Example: 2025,2030,2035,2050 creates 2025–2030, 2031–2035, 2036–2050")
    ),
    checkboxInput("show_shares", "Include shares (%) within each Plan & Period", TRUE),
    checkboxInput("pivot_wide", "Pivot wide (Technologies as columns)", FALSE),
    checkboxInput("include_total", "Include Total (all technologies)", TRUE),
    
    tags$hr(),
    downloadButton("download_filtered", "Download filtered CSV"),
    br(), br(),
    downloadButton("download_yearly", "Download yearly (Plan-Tech-Year) CSV"),
    br(), br(),
    downloadButton("download_summary", "Download summary (Plan-Period-Tech) CSV")
  ),
  
  uiOutput("main_view_ui")
)

# ---------- Server ----------
server <- function(input, output, session) {
  
  # Dynamic UI for filters
  output$plan_ui <- renderUI({
    plans <- sort(unique(raw$Plan))
    selectizeInput(
      "plan", "Plan (filter)",
      choices = plans,
      selected = plans,
      multiple = TRUE,
      options = list(plugins = list("remove_button"))
    )
  })
  
  output$tech_ui <- renderUI({
    tech <- sort(unique(raw$Technology))
    selectizeInput(
      "tech", "Technology (filter)",
      choices = tech,
      selected = tech,
      multiple = TRUE,
      options = list(plugins = list("remove_button"))
    )
  })
  
  output$year_ui <- renderUI({
    yr <- range(raw$Year, na.rm = TRUE)
    sliderInput(
      "year", "Year range",
      min = yr[1], max = yr[2],
      value = yr, step = 1, sep = ""
    )
  })
  
  # Filtered data (by Plan list, Tech list, Year range)
  df_filt <- reactive({
    req(input$plan, input$tech, input$year)
    raw %>%
      filter(
        Plan %in% input$plan,
        Technology %in% input$tech,
        Year >= input$year[1],
        Year <= input$year[2]
      )
  })
  
  # Focus plan selector for KPIs/plots (single plan)
  output$plan_focus_ui <- renderUI({
    req(input$plan)
    selectInput(
      "plan_focus",
      "Plan for KPIs/plots (single)",
      choices = input$plan,
      selected = input$plan[1]
    )
  })
  
  # Data filtered to focused plan only
  df_focus <- reactive({
    req(input$plan_focus)
    df_filt() %>% filter(Plan == input$plan_focus)
  })
  
  # ---------- KPIs (FOCUSED PLAN ONLY) ----------
  output$kpi_inv <- renderText({
    df <- df_focus()
    if (has_col(df, "INV_MIOUSD")) fmt_num(sum(df$INV_MIOUSD, na.rm = TRUE), 2) else "n/a"
  })
  
  output$kpi_gw <- renderText({
    df <- df_focus()
    if (has_col(df, "CAP_GW_Add")) {
      fmt_num(sum(df$CAP_GW_Add, na.rm = TRUE), 2)
    } else if (has_col(df, "delta_cap")) {
      fmt_num(sum(df$delta_cap, na.rm = TRUE) / 1000, 2) # MW -> GW
    } else {
      "n/a"
    }
  })
  
  output$kpi_capex <- renderText({
    df <- df_focus()
    if (has_col(df, "CAPEX_kUSD_MW")) fmt_num(mean(df$CAPEX_kUSD_MW, na.rm = TRUE), 2) else "n/a"
  })
  
  # ---------- Yearly aggregation (BY PLAN & TECHNOLOGY) ----------
  yearly <- reactive({
    df <- df_filt()
    
    cap_add <- if (has_col(df, "CAP_GW_Add")) {
      "CAP_GW_Add"
    } else if (has_col(df, "delta_cap")) {
      "delta_cap"
    } else {
      NA_character_
    }
    
    df %>%
      group_by(Plan, Year, Technology) %>%
      summarise(
        INV = if (has_col(df, "INV_MIOUSD")) sum(INV_MIOUSD, na.rm = TRUE) else NA_real_,
        INV_lwr = if (has_col(df, "INV_MIOUSD_lwr")) sum(INV_MIOUSD_lwr, na.rm = TRUE) else NA_real_,
        INV_upr = if (has_col(df, "INV_MIOUSD_upr")) sum(INV_MIOUSD_upr, na.rm = TRUE) else NA_real_,
        CAPADD = if (!is.na(cap_add)) sum(.data[[cap_add]], na.rm = TRUE) else NA_real_,
        CAPADD_unit = if (!is.na(cap_add) && cap_add == "delta_cap") "MW" else if (!is.na(cap_add)) "GW" else NA_character_,
        .groups = "drop"
      ) %>%
      mutate(CAPADD_GW = ifelse(CAPADD_unit == "MW", CAPADD / 1000, CAPADD))
  })
  
  # Yearly for focused plan only
  yearly_focus <- reactive({
    req(input$plan_focus)
    yearly() %>% filter(Plan == input$plan_focus)
  })
  
  # ---------- Plots (FOCUSED PLAN ONLY; lines = Technology) ----------
  output$plot_inv <- renderPlot({
    y <- yearly_focus()
    validate(need(any(!is.na(y$INV)), "No INV_MIOUSD column (or all missing) in filtered data."))
    
    dfp <- y %>%
      group_by(Year, Technology) %>%
      summarise(
        INV = sum(INV, na.rm = TRUE),
        INV_lwr = if (all(is.na(INV_lwr))) NA_real_ else sum(INV_lwr, na.rm = TRUE),
        INV_upr = if (all(is.na(INV_upr))) NA_real_ else sum(INV_upr, na.rm = TRUE),
        .groups = "drop"
      )
    
    ntech <- n_distinct(dfp$Technology)
    pal <- if (ntech <= 8) "Set2" else "Paired"
    show_unc <- isTRUE(input$show_uncertainty) &&
      any(!is.na(dfp$INV_lwr)) && any(!is.na(dfp$INV_upr))
    
    p <- ggplot(dfp, aes(x = Year, y = INV, colour = Technology, group = Technology))
    if (show_unc) {
      p <- p + aes(fill = Technology) +
        geom_ribbon(aes(ymin = INV_lwr, ymax = INV_upr), alpha = 0.2, colour = NA, show.legend = FALSE) +
        scale_fill_brewer(palette = pal, type = "qual")
    }
    p <- p +
      geom_line(linewidth = 1.1) +
      scale_color_brewer(palette = pal, type = "qual") +
      labs(
        x = NULL, y = "Investment (Mio USD)",
        caption = paste("Plan:", input$plan_focus, " · Lines = Technology")
      ) +
      theme_dashboard()
    p
  })
  
  output$plot_cap <- renderPlot({
    y <- yearly_focus()
    validate(need(any(!is.na(y$CAPADD_GW)), "No capacity additions column found (CAP_GW_Add or delta_cap)."))
    
    dfp <- y %>%
      group_by(Year, Technology) %>%
      summarise(CAPADD_GW = sum(CAPADD_GW, na.rm = TRUE), .groups = "drop")
    
    ntech <- n_distinct(dfp$Technology)
    pal <- if (ntech <= 8) "Set2" else "Paired"
    
    ggplot(dfp, aes(x = Year, y = CAPADD_GW, colour = Technology, group = Technology)) +
      geom_line(linewidth = 1.1) +
      scale_color_brewer(palette = pal, type = "qual") +
      labs(
        x = NULL, y = "Capacity additions (GW)",
        caption = paste("Plan:", input$plan_focus, " · Lines = Technology")
      ) +
      theme_dashboard()
  })
  
  # ---------- Period helper + Summary table (BY PLAN) ----------
  make_period <- function(year, scheme, custom_breaks = NULL) {
    year <- as.integer(year)
    
    if (scheme == "annual") return(as.character(year))
    
    if (scheme == "pdp") {
      return(dplyr::case_when(
        year >= 2025 & year <= 2030 ~ "2025–2030",
        year >= 2031 & year <= 2035 ~ "2031–2035",
        year >= 2036 & year <= 2050 ~ "2036–2050",
        TRUE ~ as.character(year)
      ))
    }
    
    if (scheme %in% c("bin5", "bin10")) {
      w <- ifelse(scheme == "bin5", 5L, 10L)
      lo <- (year %/% w) * w
      hi <- lo + (w - 1L)
      return(paste0(lo, "–", hi))
    }
    
    if (scheme == "custom") {
      br <- suppressWarnings(as.integer(trimws(unlist(strsplit(custom_breaks, ",")))))
      br <- br[!is.na(br)]
      br <- sort(unique(br))
      if (length(br) < 2) return(as.character(year))
      
      labels <- character(length(br) - 1)
      lows <- integer(length(br) - 1)
      highs <- integer(length(br) - 1)
      
      for (i in seq_len(length(br) - 1)) {
        lows[i]  <- if (i == 1) br[i] else br[i] + 1L
        highs[i] <- br[i + 1]
        labels[i] <- paste0(lows[i], "–", highs[i])
      }
      
      out <- rep(as.character(year), length(year))
      for (i in seq_along(labels)) {
        out[year >= lows[i] & year <= highs[i]] <- labels[i]
      }
      return(out)
    }
    
    as.character(year)
  }
  
  df_with_period <- reactive({
    df <- df_filt()
    df$Period <- make_period(df$Year, input$period_scheme, input$custom_breaks)
    df
  })
  
  summary_tbl <- reactive({
    df <- df_with_period()
    validate(need("INV_MIOUSD" %in% names(df), "Column INV_MIOUSD not found in the data."))
    
    s <- df %>%
      group_by(Plan, Period, Technology) %>%
      summarise(Investment_MioUSD = sum(INV_MIOUSD, na.rm = TRUE), .groups = "drop")
    
    if (isTRUE(input$include_total)) {
      s_total <- s %>%
        group_by(Plan, Period) %>%
        summarise(
          Technology = "Total",
          Investment_MioUSD = sum(Investment_MioUSD, na.rm = TRUE),
          .groups = "drop"
        )
      s <- bind_rows(s, s_total)
    }
    
    if (isTRUE(input$show_shares)) {
      s <- s %>%
        group_by(Plan, Period) %>%
        mutate(
          Share_pct = ifelse(
            Technology == "Total",
            100,
            100 * Investment_MioUSD / sum(Investment_MioUSD[Technology != "Total"], na.rm = TRUE)
          )
        ) %>%
        ungroup()
    }
    
    s <- s %>% arrange(Plan, Period, desc(Investment_MioUSD))
    
    if (isTRUE(input$pivot_wide)) {
      s <- s %>%
        select(Plan, Period, Technology, Investment_MioUSD, any_of("Share_pct")) %>%
        tidyr::pivot_wider(
          names_from  = Technology,
          values_from = Investment_MioUSD,
          values_fill = 0
        ) %>%
        arrange(Plan, Period)
    }
    
    s
  })
  
  # Focused plan summary table (for convenience, used in plots view too if wanted)
  summary_focus <- reactive({
    req(input$plan_focus)
    s <- summary_tbl()
    if ("Plan" %in% names(s)) s %>% filter(Plan == input$plan_focus) else s
  })
  
  # ---------- Main view switch ----------
  output$main_view_ui <- renderUI({
    req(input$view_mode)
    if (input$view_mode == "plots") req(input$plan_focus)
    
    if (input$view_mode == "plots") {
      tagList(
        layout_columns(
          value_box(
            title = paste0("Total Investment (Mio USD) — ", input$plan_focus),
            value = textOutput("kpi_inv"),
            icon = "dollar-sign",
            theme = "primary"
          ),
          value_box(
            title = paste0("Capacity Additions (GW) — ", input$plan_focus),
            value = textOutput("kpi_gw"),
            icon = "zap",
            theme = "success"
          ),
          value_box(
            title = paste0("Avg CAPEX (kUSD/MW) — ", input$plan_focus),
            value = textOutput("kpi_capex"),
            icon = "bar-chart-2",
            theme = "secondary"
          ),
          col_widths = c(4, 4, 4)
        ),
        
        navset_card_tab(
          title = paste("Charts & summary —", input$plan_focus),
          nav_panel(
            "Plots",
            layout_columns(
              card(
                card_header("Investment over time"),
                maybe_spinner(plotOutput("plot_inv", height = 340))
              ),
              card(
                card_header("Capacity additions over time"),
                maybe_spinner(plotOutput("plot_cap", height = 340))
              ),
              col_widths = c(6, 6)
            )
          ),
          nav_panel(
            "Summary table",
            maybe_spinner(DTOutput("tbl_summary_focus"))
          )
        )
      )
    } else {
      tagList(
        card(
          card_header("Investment summary by Plan, period, and technology"),
          maybe_spinner(DTOutput("tbl_summary"))
        ),
        card(
          card_header("Filtered data (interactive table)"),
          maybe_spinner(DTOutput("tbl"))
        )
      )
    }
  })
  
  # ---------- Tables ----------
  output$tbl <- renderDT({
    df <- df_filt()
    num_cols <- names(df)[sapply(df, is.numeric)]
    
    datatable(
      df,
      filter = "top",
      extensions = c("Buttons"),
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel")
      )
    ) %>%
      formatRound(columns = num_cols, digits = 2)
  })
  
  output$tbl_summary <- renderDT({
    df <- summary_tbl()
    num_cols <- names(df)[sapply(df, is.numeric)]
    
    datatable(
      df,
      extensions = c("Buttons"),
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel")
      )
    ) %>%
      formatRound(columns = num_cols, digits = 2)
  })
  
  output$tbl_summary_focus <- renderDT({
    df <- summary_focus()
    num_cols <- names(df)[sapply(df, is.numeric)]
    
    datatable(
      df,
      extensions = c("Buttons"),
      options = list(
        pageLength = 12,
        scrollX = TRUE,
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel")
      )
    ) %>%
      formatRound(columns = num_cols, digits = 2)
  })
  
  # ---------- Downloads ----------
  output$download_filtered <- downloadHandler(
    filename = function() paste0("Investment_filtered_", Sys.Date(), ".csv"),
    content  = function(file) write.csv(df_filt(), file, row.names = FALSE)
  )
  
  output$download_yearly <- downloadHandler(
    filename = function() paste0("Investment_yearly_plan_tech_year_", Sys.Date(), ".csv"),
    content  = function(file) write.csv(yearly(), file, row.names = FALSE)
  )
  
  output$download_summary <- downloadHandler(
    filename = function() paste0("Investment_summary_plan_period_tech_", Sys.Date(), ".csv"),
    content  = function(file) write.csv(summary_tbl(), file, row.names = FALSE)
  )
}

shinyApp(ui, server)
