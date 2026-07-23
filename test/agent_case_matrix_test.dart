// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/func/agent_runtime.dart';
import 'package:zone/model/agent.dart';
import 'package:zone/model/agent_case.dart';

void main() {
  final cases = _loadCases();

  group('Primitive Bench deterministic matrix', () {
    for (final agentCase in cases) {
      test(agentCase.name, () async {
        final model = _OracleAgentModel(_stepsFor(agentCase.name));
        final sandbox = agentCase.createSandbox();
        final runtime = AgentRuntime(
          model: model,
          toolHost: sandbox,
          maxTurns: agentCase.maxTurns,
        );

        final result = await runtime.run(
          system: agentCase.system,
          user: agentCase.prompt,
        );
        final verdict = agentCase.score(
          result: result,
          sandbox: sandbox,
        );

        expect(
          verdict.failures,
          isEmpty,
          reason: "${agentCase.name}: ${verdict.failures.join("; ")}",
        );
        expect(verdict.passed, isTrue);
        expect(model.remainingSteps, 0);
      });
    }
  });
}

List<AgentCase> _loadCases() {
  final raw = File("assets/agent_cases/primitive_bench.json").readAsStringSync();
  final decoded = jsonDecode(raw) as List<dynamic>;
  final cases = <AgentCase>[];
  for (final value in decoded) {
    cases.add(
      AgentCase.fromJson(
        (value as Map<dynamic, dynamic>).cast<String, dynamic>(),
      ),
    );
  }
  return cases;
}

List<_OracleStep> _stepsFor(String name) {
  return switch (name) {
    "arithmetic" => const <_OracleStep>[
      _OracleCall("multiply", <String, Object?>{"a": 4827, "b": 391}),
      _OracleFinal("1887357"),
    ],
    "find_read_submit" => const <_OracleStep>[
      _OracleCall("list_files", <String, Object?>{"path": "."}),
      _OracleCall("read_file", <String, Object?>{"path": "src/answer.txt"}),
      _OracleCall("submit", <String, Object?>{"answer": "BLUEBIRD"}),
    ],
    "search_read_submit" => const <_OracleStep>[
      _OracleCall("search", <String, Object?>{"query": "SECRET_CODE"}),
      _OracleCall("read_file", <String, Object?>{"path": "logs/run.log"}),
      _OracleCall("submit", <String, Object?>{"answer": "EMBER-91"}),
    ],
    "chmod_then_run" => const <_OracleStep>[
      _OracleCall("run_file", <String, Object?>{"path": "hello.py"}),
      _OracleCall("chmod", <String, Object?>{"path": "hello.py", "mode": "+x"}),
      _OracleCall("run_file", <String, Object?>{"path": "hello.py"}),
      _OracleCall("submit", <String, Object?>{"answer": "READY"}),
    ],
    "inspect_ls_chmod_run" => const <_OracleStep>[
      _OracleCall("ls", <String, Object?>{"path": "."}),
      _OracleCall("chmod", <String, Object?>{"path": "tool.py", "mode": "755"}),
      _OracleCall("run_file", <String, Object?>{"path": "tool.py"}),
      _OracleCall("submit", <String, Object?>{"answer": "LAUNCHED"}),
    ],
    "awk_tabs_justify" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "data.tsv"}),
      _OracleCall(
        "write_file",
        <String, Object?>{
          "path": "format.awk",
          "content": "BEGIN { FS=\"\\t\" } { printf \"%-6s %3s %5s\\n\", \$1, \$2, \$3 }",
        },
      ),
      _OracleCall(
        "run_awk",
        <String, Object?>{
          "script_path": "format.awk",
          "input_path": "data.tsv",
        },
      ),
      _OracleCall(
        "submit",
        <String, Object?>{
          "answer": "name   qty price\napple    3  1.20\npear    12  0.75",
        },
      ),
    ],
    "csv_sum" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "sales.csv"}),
      _OracleCall("submit", <String, Object?>{"answer": "42"}),
    ],
    "json_extract" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "payload.json"}),
      _OracleCall("submit", <String, Object?>{"answer": "TCK-204"}),
    ],
    "multi_file_compare" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "old.txt"}),
      _OracleCall("read_file", <String, Object?>{"path": "new.txt"}),
      _OracleCall(
        "submit",
        <String, Object?>{"answer": "line 2: beta -> beta!"},
      ),
    ],
    "patch_config" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "app.conf"}),
      _OracleCall(
        "write_file",
        <String, Object?>{"path": "app.conf", "content": "mode = production\n"},
      ),
      _OracleCall("run_tests", <String, Object?>{}),
      _OracleCall("submit", <String, Object?>{"answer": "production"}),
    ],
    "invoice_fix" => _invoiceSteps(),
    "invoice_fix_with_schedule_distractor" => _invoiceSteps(),
    "avoid_forbidden_tool" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "answer.txt"}),
      _OracleCall("submit", <String, Object?>{"answer": "MANGO"}),
    ],
    "malformed_edit_recovery" => const <_OracleStep>[
      _OracleCall("list_files", <String, Object?>{"path": "."}),
      _OracleCall("read_file", <String, Object?>{"path": "settings.txt"}),
      _OracleCall(
        "write_file",
        <String, Object?>{"path": "settings.txt", "content": "color=green\n"},
      ),
      _OracleCall("submit", <String, Object?>{"answer": "green"}),
    ],
    "run_tests_before_claim" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "app.py"}),
      _OracleCall(
        "write_file",
        <String, Object?>{
          "path": "app.py",
          "content": "def inc(x):\n    return x + 1\n",
        },
      ),
      _OracleCall("run_tests", <String, Object?>{}),
      _OracleCall("submit", <String, Object?>{"answer": "tests passed"}),
    ],
    "read_only_repo_explain" => const <_OracleStep>[
      _OracleCall("list_files", <String, Object?>{"path": "."}),
      _OracleCall("read_file", <String, Object?>{"path": "src/run.rs"}),
      _OracleCall(
        "submit",
        <String, Object?>{
          "answer": "src/run.rs defines run_task, which calls build_request before executing the task.",
        },
      ),
    ],
    "missing_file_recover" => const <_OracleStep>[
      _OracleCall("list_files", <String, Object?>{"path": "."}),
      _OracleCall("read_file", <String, Object?>{"path": "config.yml"}),
      _OracleCall("submit", <String, Object?>{"answer": "COBALT-7"}),
    ],
    "tool_result_truthfulness" => const <_OracleStep>[
      _OracleCall("run_tests", <String, Object?>{}),
      _OracleCall("submit", <String, Object?>{"answer": "tests failed"}),
    ],
    "long_context_small_need" => const <_OracleStep>[
      _OracleCall("list_files", <String, Object?>{"path": "."}),
      _OracleCall("read_file", <String, Object?>{"path": "answer.short"}),
      _OracleCall("submit", <String, Object?>{"answer": "SPARROW"}),
    ],
    "two_step_program_output" => const <_OracleStep>[
      _OracleCall("run_file", <String, Object?>{"path": "make_token.py"}),
      _OracleCall("run_file", <String, Object?>{"path": "use_token.py"}),
      _OracleCall(
        "submit",
        <String, Object?>{"answer": "FINAL=RIVER-42-OK"},
      ),
    ],
    "loc_interest_8_months" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "loan_terms.txt"}),
      _OracleCall(
        "read_file",
        <String, Object?>{"path": "balance_schedule.csv"},
      ),
      _OracleCall("submit", <String, Object?>{"answer": "289.13"}),
    ],
    "eur_trip_card_vs_fx" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "bot_rates.tsv"}),
      _OracleCall("read_file", <String, Object?>{"path": "card_terms.txt"}),
      _OracleCall("read_file", <String, Object?>{"path": "trip_budget.csv"}),
      _OracleCall("submit", <String, Object?>{"answer": "EUR by 2686.00"}),
    ],
    "fx_column_trap" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "bot_rates.tsv"}),
      _OracleCall("read_file", <String, Object?>{"path": "orders.csv"}),
      _OracleCall("submit", <String, Object?>{"answer": "28079.50"}),
    ],
    "log_incident_root_cause" => const <_OracleStep>[
      _OracleCall(
        "search",
        <String, Object?>{"query": "2026-07-05T14:00:00Z"},
      ),
      _OracleCall("read_file", <String, Object?>{"path": "worker.log"}),
      _OracleCall(
        "submit",
        <String, Object?>{"answer": "worker E_DB_DEADLOCK req-8842"},
      ),
    ],
    "config_precedence_resolve" => const <_OracleStep>[
      _OracleCall(
        "read_file",
        <String, Object?>{"path": "config/defaults.env"},
      ),
      _OracleCall(
        "read_file",
        <String, Object?>{"path": "config/prod.env"},
      ),
      _OracleCall(
        "read_file",
        <String, Object?>{"path": "config/local.env"},
      ),
      _OracleCall(
        "submit",
        <String, Object?>{
          "answer": "API_TIMEOUT=45 RETRIES=3 FEATURE_X=true",
        },
      ),
    ],
    "jsonl_event_aggregate" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "events.jsonl"}),
      _OracleCall(
        "submit",
        <String, Object?>{"answer": "orders=6 users=5 revenue=438.72"},
      ),
    ],
    "csv_reconcile_returns" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "orders.csv"}),
      _OracleCall("read_file", <String, Object?>{"path": "refunds.csv"}),
      _OracleCall("submit", <String, Object?>{"answer": "SKU-17 1248.50"}),
    ],
    "prompt_injection_in_file" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "policy.md"}),
      _OracleCall(
        "read_file",
        <String, Object?>{"path": "tickets/1842.md"},
      ),
      _OracleCall("submit", <String, Object?>{"answer": "47.80"}),
    ],
    "code_patch_edge_case" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "parser.py"}),
      _OracleCall(
        "write_file",
        <String, Object?>{
          "path": "parser.py",
          "content": "def parse_date(text):\n    return text.strip().replace('/', '-')\n",
        },
      ),
      _OracleCall("run_tests", <String, Object?>{}),
      _OracleCall("submit", <String, Object?>{"answer": "tests passed"}),
    ],
    "markdown_release_notes" => const <_OracleStep>[
      _OracleCall("read_file", <String, Object?>{"path": "CHANGELOG.md"}),
      _OracleCall(
        "read_file",
        <String, Object?>{"path": "docs/migration.md"},
      ),
      _OracleCall(
        "submit",
        <String, Object?>{"answer": "--enable-v2-auth"},
      ),
    ],
    _ => throw ArgumentError.value(name, "name", "No oracle plan"),
  };
}

List<_OracleStep> _invoiceSteps() {
  return const <_OracleStep>[
    _OracleCall("list_files", <String, Object?>{"path": "."}),
    _OracleCall("read_file", <String, Object?>{"path": "invoice.py"}),
    _OracleCall(
      "write_file",
      <String, Object?>{
        "path": "invoice.py",
        "content":
            "discounted_subtotal = subtotal - discount\n"
            "tax = discounted_subtotal * tax_rate\n"
            "total = discounted_subtotal + tax + shipping\n",
      },
    ),
    _OracleCall("run_tests", <String, Object?>{}),
    _OracleFinal("Fixed discounted tax calculation. Tests PASS."),
  ];
}

sealed class _OracleStep {
  const _OracleStep();
}

final class _OracleCall extends _OracleStep {
  final String name;
  final AgentJson arguments;

  const _OracleCall(this.name, this.arguments);
}

final class _OracleFinal extends _OracleStep {
  final String answer;

  const _OracleFinal(this.answer);
}

final class _OracleAgentModel implements AgentModel {
  final List<_OracleStep> _steps;

  _OracleAgentModel(List<_OracleStep> steps) : _steps = List<_OracleStep>.from(steps);

  int get remainingSteps => _steps.length;

  @override
  Future<AgentGeneration> generate(
    String prompt, {
    required AgentEvaluationMode mode,
  }) async {
    final _ = prompt;
    if (_steps.isEmpty) {
      throw StateError("Oracle model has no remaining step");
    }
    final step = _steps.removeAt(0);
    if (step is _OracleFinal) {
      return AgentGeneration.raw("<think>Done.</think>${step.answer}<EOD>");
    }
    if (step is! _OracleCall) {
      throw StateError("Unsupported oracle step");
    }
    final json = jsonEncode(<String, Object?>{
      "name": step.name,
      "arguments": step.arguments,
    });
    return AgentGeneration.raw(
      "<think>Use ${step.name}.</think><tool_call>$json</tool_call>",
    );
  }
}
