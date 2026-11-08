"""Ticket syntax regressions; no credentials or network calls."""
import importlib.util
import io
import json
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

D = load('delivery_keys', '.nakama/kaicho_delivery.py')
G = load('governance_keys', 'scripts/nakama_governance.py')
PROFILE = {'default_branch': 'main'}
POLICY = {'LINEAR_TEAM_KEY':'NAK', 'LINEAR_PROJECT_NAME':'Synthetic Project', 'PROTECTED_BRANCHES':'main'}

class TicketKeys(unittest.TestCase):
    def test_distinct_keys_keep_existing_branch_layouts(self):
        for key in ('ABC', 'DOC', 'QA2', 'Z'):
            self.assertIsNone(D.branch_error(f'fix/{key}-123-description', PROFILE))
            self.assertIsNone(G.validate_branch_format(f'fix/cx/{key}-123-description', POLICY))
            self.assertIsNone(D.message_error(f'fix: retain ticket\n\nRefs {key}-123'))

    def test_missing_and_malformed_references_fail(self):
        for ticket in ('', 'ABC', 'ABC-', 'ABC-0', 'ABC-01', 'ABC-one', '123-4', 'İ-123', 'KEY-123'):
            self.assertIsNotNone(D.branch_error(f'fix/{ticket}-description', PROFILE))
            self.assertIsNotNone(G.validate_branch_format(f'fix/cx/{ticket}-description', POLICY))
            self.assertIsNotNone(D.message_error(f'fix: retain ticket\n\nRefs {ticket}'))
        for suffix in ('garbage', '.5', '/other', '_tail', '-extra'):
            self.assertIsNotNone(D.message_error(f'fix: retain ticket\n\nRefs ABC-123{suffix}'))
        self.assertIsNotNone(D.message_error('fix: missing ticket'))

    def test_existing_online_existence_and_project_gate(self):
        valid = {'identifier':'ABC-123','team':{'key':'ABC'},'project':{'name':'Synthetic Project'}}
        def result(issue):
            return io.BytesIO(json.dumps({'data':{'issue':issue}}).encode())
        with patch.object(G.urllib.request, 'urlopen', return_value=result(valid)) as query:
            G.linear_issue('fix/cx/ABC-123-description', POLICY, 'synthetic-fixture', 'https://example.invalid/graphql')
            self.assertEqual(json.loads(query.call_args.args[0].data)['variables']['id'], 'ABC-123')
        for issue in (None, valid | {'identifier':'ABC-124'}, valid | {'project':{'name':'Other Project'}}):
            with patch.object(G.urllib.request, 'urlopen', return_value=result(issue)):
                with self.assertRaises(SystemExit):
                    G.linear_issue('fix/cx/ABC-123-description', POLICY, 'synthetic-fixture', 'https://example.invalid/graphql')
        with patch.object(G.urllib.request, 'urlopen', side_effect=OSError('synthetic unavailable')):
            with self.assertRaises(SystemExit):
                G.linear_issue('fix/cx/ABC-123-description', POLICY, 'synthetic-fixture', 'https://example.invalid/graphql')
