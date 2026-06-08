# SimulationResultsFinancialInstruments.R
#
# R equivalent of save_figures_for_scenarios_finance.m
# Produces 9 core financing figures + 1 summary panel for the DGE-METRIC model.
#
# Scenarios:
#   Baseline          → "PDP8-Base"
#   PDP8_concessional → "PDP8-Concessional"
#   PDP8_subsidies    → "PDP8-Recycle"
#   NZ                → "NZ-Base"
#   NZ_concessional   → "NZ-Concessional"
#   NZ_subsidies      → "NZ-Recycle"
#
# Output: Figures/Financing/*.pdf + *.png
#
# Run from project root:
#   setwd("C:/Users/schul/Documents/GitHub/DGE-METRIC")
#   source("SimulationResultsFinancialInstruments.R")

# ── 0. Packages ────────────────────────────────────────────────────────────────

for (pkg in c("tidyverse", "scales", "patchwork")) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
library(tidyverse)
library(scales)
library(patchwork)

DATA_DIR <- "ExcelFiles/Output"
FIG_DIR  <- file.path("Figures", "Financing")
if (!dir.exists(FIG_DIR)) dir.create(FIG_DIR, recursive = TRUE)

TPLOT <- 26   # 26 periods: 2025–2050 (matching MATLAB Tplot = 26)

# ── 1. Colour / line-style palette (matching MATLAB) ──────────────────────────
# PDP8 → blue #1f77b4;  NZ → red #d62728

COL_PDP8 <- "#1f77b4"
COL_NZ   <- "#d62728"

SCENARIOS <- tribble(
  ~file,              ~label,               ~color,    ~lty,     ~group,
  "Baseline",         "PDP8-Base",          COL_PDP8,  "solid",  "all",
  "PDP8_concessional","PDP8-Concessional",  COL_PDP8,  "dashed", "all",
  "PDP8_subsidies",   "PDP8-Recycle",       COL_PDP8,  "dotdash","all",
  "NZ",               "NZ-Base",            COL_NZ,    "solid",  "all",
  "NZ_concessional",  "NZ-Concessional",    COL_NZ,    "dashed", "all",
  "NZ_subsidies",     "NZ-Recycle",         COL_NZ,    "dotdash","all"
)

POLICY <- tribble(
  ~file,              ~label,                          ~base_file, ~color,   ~lty,
  "PDP8_concessional","PDP8 concessional vs PDP8 base","Baseline", COL_PDP8, "dashed",
  "PDP8_subsidies",   "PDP8 recycle vs PDP8 base",    "Baseline", COL_PDP8, "dotdash",
  "NZ_concessional",  "NZ concessional vs NZ base",   "NZ",       COL_NZ,   "dashed",
  "NZ_subsidies",     "NZ recycle vs NZ base",        "NZ",       COL_NZ,   "dotdash"
)

# ── 2. Load data ───────────────────────────────────────────────────────────────

load_csv <- function(file_name) {
  read_csv(file.path(DATA_DIR, paste0(file_name, ".csv")),
           show_col_types = FALSE)
}

ds <- map(set_names(SCENARIOS$file), load_csv)

# Verify which rate variable to use for "public interest rate"
# (r_G_3_1 unless it never changes vs baseline, then fall back to r_F_3_1)
spread_rG <- max(abs(ds$PDP8_concessional$r_G_1_1[seq_len(TPLOT)] -
                      ds$Baseline$r_G_1_1[seq_len(TPLOT)]))
RATE_VAR <- if (spread_rG < 1e-10) "r_F_3_1" else "r_G_3_1"

# ── 3. Shared theme ────────────────────────────────────────────────────────────

theme_fin <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor  = element_blank(),
      panel.grid.major  = element_line(colour = "grey93"),
      legend.position   = "bottom",
      legend.title      = element_blank(),
      legend.key.width  = unit(1.6, "cm"),
      axis.title        = element_text(face = "bold"),
      strip.text        = element_text(face = "bold"),
      plot.title        = element_text(face = "bold", size = base_size + 1),
      plot.caption      = element_text(colour = "grey50", size = 9),
      plot.margin       = margin(8, 14, 8, 8)
    )
}

# ── 4. Helper functions ────────────────────────────────────────────────────────

# Build a tidy data frame for "all scenarios" plots
tidy_all <- function(var_fn, year_col = TRUE) {
  pmap_dfr(SCENARIOS, function(file, label, color, lty, group) {
    d <- ds[[file]]
    yrs <- d$Year[seq_len(TPLOT)]
    vals <- var_fn(d)[seq_len(TPLOT)]
    tibble(Year = yrs, value = vals,
           label = label, color = color, lty = lty)
  })
}

# Build a tidy data frame for "policy vs baseline" plots
tidy_policy <- function(var_fn_policy, var_fn_base) {
  pmap_dfr(POLICY, function(file, label, base_file, color, lty) {
    d_pol  <- ds[[file]]
    d_base <- ds[[base_file]]
    yrs <- d_pol$Year[seq_len(TPLOT)]
    vals <- var_fn_policy(d_pol, d_base)[seq_len(TPLOT)]
    tibble(Year = yrs, value = vals,
           label = label, color = color, lty = lty)
  })
}

# Save figure as PDF + PNG (matches MATLAB save_my_figure)
save_fig <- function(p, name, width = 11, height = 6.5) {
  safe_name <- gsub("[^A-Za-z0-9_\\-]", "_", name)
  ggsave(file.path(FIG_DIR, paste0(safe_name, ".pdf")),
         p, width = width, height = height)
  ggsave(file.path(FIG_DIR, paste0(safe_name, ".png")),
         p, width = width, height = height, dpi = 200)
  message("Saved ", safe_name)
}

# Shared scale helpers
scale_col_all <- function() {
  scale_colour_manual(
    values = setNames(SCENARIOS$color, SCENARIOS$label)
  )
}
scale_lty_all <- function() {
  scale_linetype_manual(
    values = setNames(SCENARIOS$lty, SCENARIOS$label)
  )
}
scale_col_pol <- function() {
  scale_colour_manual(
    values = setNames(POLICY$color, POLICY$label)
  )
}
scale_lty_pol <- function() {
  scale_linetype_manual(
    values = setNames(POLICY$lty, POLICY$label)
  )
}

base_gg <- function(df) {
  ggplot(df, aes(x = Year, y = value,
                 colour = label, linetype = label)) +
    geom_line(linewidth = 1.15) +
    scale_x_continuous(breaks = seq(2025, 2050, by = 5)) +
    theme_fin()
}

# Zero-line helper for deviation plots
zero_line <- geom_hline(
  yintercept = 0, linetype = "dotted",
  colour = "grey50", linewidth = 0.8
)

# ── 5. Figure 1: Public interest rate (levels, %) ─────────────────────────────

df1 <- tidy_all(function(d) d[[RATE_VAR]] * 100)

fig1 <- base_gg(df1) +
  scale_col_all() + scale_lty_all() +
  labs(
    title   = "Public interest rate",
    x       = "Year",
    y       = "Percent",
    caption = paste0("Variable: ", RATE_VAR, " × 100")
  ) +
  guides(colour   = guide_legend(nrow = 2, override.aes = list(linewidth = 1.5)),
         linetype = guide_legend(nrow = 2))

save_fig(fig1, "PublicInterestRate")

# ── 6. Figure 2: Renewable capital stock (indexed 2025 = 100) ─────────────────

df2 <- tidy_all(function(d) d$K_3_1 / d$K_3_1[1] * 100)

fig2 <- base_gg(df2) +
  scale_col_all() + scale_lty_all() +
  geom_hline(yintercept = 100, linetype = "dotted",
             colour = "grey50", linewidth = 0.8) +
  labs(
    title = "Renewable capital stock",
    x     = "Year",
    y     = "Index (2025 = 100)"
  ) +
  guides(colour   = guide_legend(nrow = 2, override.aes = list(linewidth = 1.5)),
         linetype = guide_legend(nrow = 2))

save_fig(fig2, "RenewableCapital")

# ── 7. Figure 3: GDP growth (pp deviation from pathway baseline) ───────────────

df3 <- tidy_policy(
  var_fn_policy = function(d_pol, d_base) {
    g_pol  <- (d_pol$Y_1[2:TPLOT]  / d_pol$Y_1[1:(TPLOT - 1)]  - 1) * 100
    g_base <- (d_base$Y_1[2:TPLOT] / d_base$Y_1[1:(TPLOT - 1)] - 1) * 100
    c(NA_real_, g_pol - g_base)   # prepend NA so length = TPLOT
  },
  var_fn_base = NULL
) %>% filter(!is.na(value))

fig3 <- base_gg(df3) +
  zero_line +
  scale_col_pol() + scale_lty_pol() +
  labs(
    title = "GDP growth",
    x     = "Year",
    y     = "Percentage points vs pathway baseline"
  ) +
  guides(colour   = guide_legend(nrow = 2, override.aes = list(linewidth = 1.5)),
         linetype = guide_legend(nrow = 2))

save_fig(fig3, "GDP_Growth")

# ── 8. Figure 4: GDP level (% vs pathway baseline) ────────────────────────────

df4 <- tidy_policy(
  var_fn_policy = function(d_pol, d_base) {
    (d_pol$Y_1 / d_base$Y_1 - 1) * 100
  }
)

fig4 <- base_gg(df4) +
  zero_line +
  scale_col_pol() + scale_lty_pol() +
  labs(
    title = "GDP level",
    x     = "Year",
    y     = "% vs pathway baseline"
  ) +
  guides(colour   = guide_legend(nrow = 2, override.aes = list(linewidth = 1.5)),
         linetype = guide_legend(nrow = 2))

save_fig(fig4, "GDP")

# ── 9. Figure 5: Total investment (% vs pathway baseline) ─────────────────────

df5 <- tidy_policy(
  var_fn_policy = function(d_pol, d_base) {
    (d_pol$I_1 / d_base$I_1 - 1) * 100
  }
)

fig5 <- base_gg(df5) +
  zero_line +
  scale_col_pol() + scale_lty_pol() +
  labs(
    title = "Total investment",
    x     = "Year",
    y     = "% vs pathway baseline"
  ) +
  guides(colour   = guide_legend(nrow = 2, override.aes = list(linewidth = 1.5)),
         linetype = guide_legend(nrow = 2))

save_fig(fig5, "Investment")

# ── 10. Figure 6: Emission tax revenue (model units) ──────────────────────────

df6 <- tidy_all(function(d) d$PE_1 * d$E_1)

fig6 <- base_gg(df6) +
  scale_col_all() + scale_lty_all() +
  labs(
    title   = "Emission tax revenue",
    x       = "Year",
    y       = "Model units",
    caption = "PE_1 × E_1"
  ) +
  guides(colour   = guide_legend(nrow = 2, override.aes = list(linewidth = 1.5)),
         linetype = guide_legend(nrow = 2))

save_fig(fig6, "EmissionTaxRevenue")

# ── 11. Figure 7: Recycled renewable investment (Billion USD, 2015) ───────────
# Scale factor 500: matches MATLAB (PE_1 * E_1 / Y_NZ_base_t0 * 500)

Y_base_t0 <- ds[["NZ"]]$Y[1]

df7 <- tidy_policy(
  var_fn_policy = function(d_pol, d_base) {
    d_pol$PE_1 * d_pol$E_1 / Y_base_t0 * 500
  }
)

fig7 <- base_gg(df7) +
  zero_line +
  scale_col_pol() + scale_lty_pol() +
  labs(
    title   = "Recycled renewable investment",
    x       = "Year",
    y       = "Billion USD (2015)",
    caption = "PE_1 × E_1 / Y_NZ(t=0) × 500"
  ) +
  guides(colour   = guide_legend(nrow = 2, override.aes = list(linewidth = 1.5)),
         linetype = guide_legend(nrow = 2))

save_fig(fig7, "RecycledInvestment")

# ── 12. Figure 8: Emissions (Mio. t CO₂, indexed with scale 300) ──────────────

df8 <- tidy_all(function(d) d$E_1 / d$E_1[1] * 300)

fig8 <- base_gg(df8) +
  scale_col_all() + scale_lty_all() +
  labs(
    title   = "Emissions",
    x       = "Year",
    y       = expression("Mio. t CO"[2]),
    caption = "E_1 / E_1(2025) × 300  (scale converts model units to Mio. t CO₂)"
  ) +
  guides(colour   = guide_legend(nrow = 2, override.aes = list(linewidth = 1.5)),
         linetype = guide_legend(nrow = 2))

save_fig(fig8, "Emissions")

# ── 13. Figure 9: Renewable generation (indexed 2025 = 100) ───────────────────

df9 <- tidy_all(function(d) d$Q_3_1 / d$Q_3_1[1] * 100)

fig9 <- base_gg(df9) +
  geom_hline(yintercept = 100, linetype = "dotted",
             colour = "grey50", linewidth = 0.8) +
  scale_col_all() + scale_lty_all() +
  labs(
    title = "Renewable generation",
    x     = "Year",
    y     = "Index (2025 = 100)"
  ) +
  guides(colour   = guide_legend(nrow = 2, override.aes = list(linewidth = 1.5)),
         linetype = guide_legend(nrow = 2))

save_fig(fig9, "RenewableGeneration")

# ── 14. Figure 10: Summary panel (patchwork 2×2) ──────────────────────────────

p_rate <- fig1 + labs(title = "Public interest rate (%)") + theme(legend.position = "none")
p_cap  <- fig2 + labs(title = "Renewable capital (index)")+ theme(legend.position = "none")
p_gdp  <- fig4 + labs(title = "GDP vs pathway baseline (%)") + theme(legend.position = "none")
p_ems  <- fig8 + labs(title = expression("Emissions (Mio. t CO"[2]*")")) +
          theme(legend.position = "none")

# Shared legend from fig4 (policy scenarios, 4 entries)
legend_grob <- cowplot::get_legend(
  fig4 + theme(legend.position = "bottom",
               legend.text = element_text(size = 11))
)

fig10 <- (p_rate + p_cap) / (p_gdp + p_ems) +
  plot_annotation(
    title    = "DGE-METRIC – Financial Instruments Summary",
    subtitle = "PDP8 and NZ pathways with concessional lending and emission-tax recycling",
    theme    = theme(
      plot.title    = element_text(face = "bold", size = 15),
      plot.subtitle = element_text(colour = "grey40", size = 12)
    )
  )

# Try to attach shared legend (requires cowplot; skip gracefully if not available)
if (requireNamespace("cowplot", quietly = TRUE)) {
  fig10_legend <- cowplot::plot_grid(
    fig10,
    cowplot::get_legend(
      fig1 + theme(legend.position = "bottom",
                   legend.text = element_text(size = 11))
    ),
    ncol = 1, rel_heights = c(1, 0.08)
  )
  save_fig(fig10_legend, "Summary_Panel", width = 13, height = 9)
} else {
  save_fig(fig10, "Summary_Panel", width = 13, height = 9)
}

# ── Done ──────────────────────────────────────────────────────────────────────

message("\nAll financing figures saved to: ", normalizePath(FIG_DIR))
message("Files: PublicInterestRate, RenewableCapital, GDP_Growth, GDP,")
message("       Investment, EmissionTaxRevenue, RecycledInvestment,")
message("       Emissions, RenewableGeneration, Summary_Panel")
message("PDF + PNG versions for each.")
